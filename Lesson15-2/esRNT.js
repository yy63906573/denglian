import { createPublicClient, http } from 'viem';
import { localhost } from 'viem/chains';
import { keccak256, encodePacked, pad, hexToBigInt, hexToNumber, isAddress, toHex } from 'viem/utils';
// 假设你的 esRNT 合约已部署在本地开发链上
const client = createPublicClient({
    chain: localhost, // 或者你的目标链，如 mainnet, sepolia 等
    transport: http('http://127.0.0.1:8545'), // 你的节点 RPC URL
});

// 请替换为你的 esRNT 合约实际部署的地址
const esRNT_CONTRACT_ADDRESS = '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512'; // 示例地址

// esRNT 合约 ABI 片段，只包含我们需要的 constructor 和 _locks 状态变量（虽然我们直接读存储插槽，但这是为了上下文）
// 实际上，我们不需要 ABI 来使用 getStorageAt，但了解合约结构很重要
const esRNTAbi = [
    {
        "inputs": [],
        "stateMutability": "nonpayable",
        "type": "constructor"
    }
];


async function readLocks() {
    console.log(`正在从合约地址 ${esRNT_CONTRACT_ADDRESS} 读取 _locks 数组...`);

    // 步骤 1: 获取 _locks 数组长度所在的存储插槽 (slot 0)
    const arrayLengthSlot = '0x0'; // _locks 是第一个状态变量，位于插槽 0

    // 读取数组的长度 (存储在 slot 0)
    const lengthHex = await client.getStorageAt({
        address: esRNT_CONTRACT_ADDRESS,
        slot: arrayLengthSlot,
    });

    if (!lengthHex) {
        console.error("无法读取数组长度，请确保合约已部署且地址正确。");
        return;
    }

    const arrayLength = hexToNumber(lengthHex);
    console.log(`_locks 数组的长度为: ${arrayLength}`);

    if (arrayLength === 0) {
        console.log("数组为空，没有元素可读取。");
        return;
    }

    // 步骤 2: 计算数组元素起始存储位置的哈希 (keccak256(slot(0)))
    // pad('0x0', { size: 32 }) 确保插槽号是 32 字节的 HexString
    const baseStorageSlot = keccak256(pad(arrayLengthSlot, { size: 32 }));

    console.log(`数组元素的基础存储插槽 (keccak256(0)) 为: ${baseStorageSlot}`);

    // 遍历读取每个 LockInfo 结构体
    for (let i = 0; i < arrayLength; i++) {
        // 每个 LockInfo 结构体占用 2 个插槽
        // 第一个插槽存储 user 和 startTime
        // 第二个插槽存储 amount
        // 每个 LockInfo 占用 2 个插槽，所以当前插槽的索引为
        const currentElementSlotBase = hexToBigInt(baseStorageSlot) + BigInt(i * 2);

        // 读取第一个插槽 (user 和 startTime)
        const slot1Hex = await client.getStorageAt({
            address: esRNT_CONTRACT_ADDRESS,
            slot: toHex(currentElementSlotBase, { size: 32 }),

        });

        // 读取第二个插槽 (amount)
        const slot2Hex = await client.getStorageAt({
            address: esRNT_CONTRACT_ADDRESS,
            slot: toHex(currentElementSlotBase + BigInt(1), { size: 32 }),
        });

        if (!slot1Hex || !slot2Hex) {
            console.error(`无法读取 _locks[${i}] 的数据。`);
            continue;
        }

        // 解析 slot1Hex: 地址 (user) 占用低 20 字节，uint64 (startTime) 占用高 8 字节
        // Viem 的 hexToAddress 会自动处理 padding，所以我们可以直接提取
        // const user = `0x${slot1Hex.slice(26)}`; // 地址在低 20 字节，所以从索引 26 (2 + 32 - 20) 开始
        // const startTime = hexToNumber(`0x${slot1Hex.slice(2, 18)}`); // uint64 占用 8 字节 (16 个十六进制字符)

        // 解析 slot1Hex: 地址 (user) 占用低 20 字节，uint64 (startTime) 占用其前的 8 字节
        const user = `0x${slot1Hex.slice(26)}`; // user 解析仍然保持不变，这是正确的

        // startTime 在地址之前，占据 8 字节，其起始位置是 32 - 20 - 8 = 4 字节的偏移 (对应 8 个十六进制字符)
        // 所以从 `0x` 后面的第 8 个十六进制字符开始取 16 个字符 (8 字节)
        const startTime = hexToNumber(`0x${slot1Hex.slice(2 + 8, 2 + 8 + 16)}`); // slice(10, 26)


        // 解析 slot2Hex: amount (uint256)
        const amount = hexToBigInt(slot2Hex);

        console.log(`locks[${i}]: user: ${user}, startTime: ${startTime}, amount: ${amount.toString()}`);
    }
}

// 运行函数
readLocks().catch(console.error);