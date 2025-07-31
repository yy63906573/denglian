//这是一个实现EIP7702的项目工程，本地打包签名，from和to地址可以都为EOA账户，但是签名必须加self，如下
// const authorization = await client.signAuthorization({
//         account: account,
//         contractAddress:delegateContractAddress,
//         executor: 'self', 
//     })
//from地址和to不同时， to地址必须和签名地址一致
// const client = createWalletClient({
//     account: txaccount,  // from地址
//     chain: sepolia,
//     transport: http(rpcUrl),
// });
// const authorization = await client.signAuthorization({
//         account: account,//to地址
//         contractAddress:delegateContractAddress,
//         executor: 'self', 
//     })

//EOA账户识别出这是一个 mulicall 合约，会把mulicall的函数拿到EOA账户的方法区去实现
//发送交易时要有authorizationList 参数才能识别是mulicall合约
// --- 导入 viem 核心模块 ---
import { createWalletClient, createPublicClient, http, encodeFunctionData, parseUnits, hexToSignature, toHex } from 'viem';
import { sepolia } from 'viem/chains'; // 注意：EIP-7702 实践通常在测试网进行
import { privateKeyToAccount } from 'viem/accounts';

// --- 配置部分 ---
// 你的 DApp 连接的以太坊网络
const rpcUrl = 'https://sepolia.infura.io/v3/ec27bdf38453436683b5f6438a97741f'; // 替换为你的Sepolia RPC URL


// EOA 账户，从私钥创建
// !! 在实际应用中，绝不能将私钥明文保存在代码中，应通过钱包（如 MetaMask）获取 !!
const account = privateKeyToAccount('0x85f4aa9e8a737a0beeaa3b4565ef466e00edcfcd719d7584ba731c158ccf35da');
const txaccount = privateKeyToAccount('0x47c972973e1260e754a89977e5d678bac9681c0902391b79fcdfab6ae68aeed4');

// 委托合约的地址。
const delegateContractAddress = '0x4c95eFfe330313F6eE14243c5AdDaEFe953B7427';

// --- 准备批量操作的 calldata ---
//const tokenAbi = [{ "inputs": [{ "internalType": "address", "name": "spender", "type": "address" }, { "internalType": "uint256", "name": "amount", "type": "uint256" }], "name": "approve", "outputs": [{ "internalType": "bool", "name": "", "type": "bool" }], "stateMutability": "nonpayable", "type": "function" }];
const tokenAddress = '0x8F9Db5C035cdada3a125De9A0A0B80427bdafD0b'; // 替换为Sepolia上的代币地址
// 委托合约的地址。
const tokenBankAddress = '0x02927636e1f7E1D1bA587F31D0dA4Ab5D2D79506';


//const address = delegateContractAddress;

const client = createWalletClient({
    account: txaccount,
    chain: sepolia, // 选择Sepolia测试网
    transport: http(rpcUrl),
});

// const walletClient = createWalletClient({
//     account: account,
//     chain: sepolia, // 选择Sepolia测试网
//     transport: http(rpcUrl),
// });


// 创建公共客户端，用于查询链上数据
const publicClient = createPublicClient({
    chain: sepolia,
    transport: http(rpcUrl),
});

const chainId = BigInt(client.chain.id);
const nonce = await publicClient.getTransactionCount({ address: account.address });

console.log(chainId);
// 假设我们进行一个授权操作
const approveCalldata = encodeFunctionData({
    abi: [
        {
            name: 'approve',
            type: 'function',
            stateMutability: 'nonpayable',
            inputs: [
                { name: 'spender', type: 'address' },
                { name: 'amount', type: 'uint256' }
            ],
            outputs: [{ name: '', type: 'bool' }]
        }
    ],
    functionName: 'approve',
    args: [tokenBankAddress, parseUnits('100', 18)], // 授权给 Delegate 合约
});


// 假设我们进行一个存款操作
//const depositAbi = [{ "inputs": [{ "internalType": "uint256", "name": "amount", "type": "uint256" }], "name": "deposit", "outputs": [], "stateMutability": "nonpayable", "type": "function" }];

const depositCalldata = encodeFunctionData({
    abi: [
        {
            name: 'deposit',
            type: 'function',
            stateMutability: 'nonpayable',
            inputs: [
                { name: 'amount', type: 'uint256' },
            ],
            outputs: [],
        },
    ],
    functionName: 'deposit',
    args: [parseUnits('50', 18)], // 存入100个代币
});

// 将多个操作打包成 calls 数组，以匹配 Delegate 合约的 execute 方法
const calls = [
    { target: tokenAddress, value: 0, data: approveCalldata },
    { target: tokenBankAddress, value: 0, data: depositCalldata },
];
console.log(calls);
// 使用新的 ABI 编码 execute 方法的 calldata
const executeAbi = [{ "type": "function", "name": "execute", "inputs": [{ "name": "calls", "type": "tuple[]", "internalType": "struct Delegate.Call[]", "components": [{ "name": "target", "type": "address", "internalType": "address" }, { "name": "value", "type": "uint256", "internalType": "uint256" }, { "name": "data", "type": "bytes", "internalType": "bytes" }] }], "outputs": [], "stateMutability": "payable" }];

const encodedExecuteData = encodeFunctionData({
    abi: executeAbi,
    functionName: 'execute',
    args: [calls],
});


// --- EIP-7702 签名和交易发送部分 ---
async function sendEIP7702Transaction() {

    const authorization = await client.signAuthorization({
        account: account,
        contractAddress:delegateContractAddress,
        //executor: 'self', 
    })

    console.log(authorization);

    const eip7702Tx = {
        //account,
        to: account.address, // 交易目标是 Delegate 合约
        data: encodedExecuteData, // 使用新的 execute calldata
        authorizationList: [authorization],
        // viem 会根据 authorizationList 字段推断出交易类型
    };

    // 4. 将 Type 4 交易发送到以太坊网络
    console.log("正在发送 EIP-7702 交易...");
    const txHash = await client.sendTransaction(eip7702Tx);
    console.log(`交易哈希: ${txHash}`);

    // 等待交易被打包
    const receipt = await publicClient.waitForTransactionReceipt({ hash: txHash })
    console.log("交易已确认。批量操作已成功执行。", receipt);
}

// 调用主函数
sendEIP7702Transaction().catch(console.error);

