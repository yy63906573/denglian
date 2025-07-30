// scripts/generate-merkle.mjs
import { MerkleTree } from 'merkletreejs'; //引入merkletreejs
import keccak256 from 'keccak256';

// 使用 Foundry `vm.addr()` 和 `vm.deal()` 中常见的地址，方便测试
const whitelistAddresses = [
  "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266", // Anvil account 1 (PK: 0x59c6... )
  "0x70997970C51812dc3A010C7d01b50e0d17dc79C8", // Anvil account 2
  "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC", // Anvil account 3
  "0x90F79bf6EB2c4f870365E785982E1f101E93b906", // Anvil account 4
  "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65", // Anvil account 5
  "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc", // Anvil account 6
  "0x976EA74026E726554dB657fA54763abd0C3a0aa9", // Anvil account 7
  "0x14dC79964da2C08b23698B3D3cc7Ca32193d9955", // Anvil account 8
  "0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f", // Anvil account 9
  "0xa0Ee7A142d267C1f36714E4a8F75612F20a79720", // Anvil account 10
];

// 生成 Merkle 树
const leaves = whitelistAddresses.map(addr => keccak256(addr));
// 使用 keccak256 哈希函数对地址进行哈希处理，并生成 Merkle 树
const merkleTree = new MerkleTree(leaves, keccak256, { sortPairs: true });
// 获取 Merkle 树的根哈希
// 这将用于验证地址是否在白名单中
const root = merkleTree.getHexRoot();

// 为第一个地址生成证明，将在测试和部署中使用它
const claimingAddress = whitelistAddresses[0];
const proof = merkleTree.getHexProof(keccak256(claimingAddress));

console.log("Merkle Root:", root);
console.log(`\nProof for ${claimingAddress}:`);
console.log(JSON.stringify(proof)); // 打印为JSON数组，方便在Solidity中复制粘贴

