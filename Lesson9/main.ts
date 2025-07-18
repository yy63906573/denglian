import { http, createWalletClient, custom, formatUnits, parseUnits, createPublicClient, getContract } from 'viem';
import { sepolia } from 'viem/chains';
import type { MetaMaskInpageProvider } from '@metamask/providers';
import type { Abi } from 'viem';
import tokenBankAbi from './abis/TokenBank.json';
import erc20Abi from './abis/MyERC20V3.json';

declare global {
    interface Window {
        ethereum?: MetaMaskInpageProvider;
    }
}

//tokenBank address       0x02927636e1f7E1D1bA587F31D0dA4Ab5D2D79506
const tokenBankAddress = '0x02927636e1f7E1D1bA587F31D0dA4Ab5D2D79506';
//ERC20 token address
const erc20Address = '0x8F9Db5C035cdada3a125De9A0A0B80427bdafD0b';

const connectBtn = document.getElementById('connect')!;
const depositBtn = document.getElementById('depositBtn')!;
const withdrawBtn = document.getElementById('withdrawBtn')!;
const addressSpan = document.getElementById('address')!;
const balanceSpan = document.getElementById('balance')!;
const depositSpan = document.getElementById('deposit')!;
// const privateKey = "0x47c972973e1260e754a89977e5d678bac9681c0902391b79fcdfab6ae68aeed4";
const privateKey = "0x80Ee32778108B44D966923E85eE46D9C5c50dCb7";
let account: `0x${string}` | null = null;

if (!window.ethereum) {
    throw new Error('请安装 MetaMask 钱包以继续');
}

const client = createWalletClient({
    account: privateKey,
    chain: sepolia,
    transport: custom(window.ethereum),
});

const pubClient = createPublicClient({
    chain: sepolia,
    transport: custom(window.ethereum),
});

const erc20 = getContract({
    address: erc20Address,
    abi: erc20Abi.abi as Abi,
    client: {
        public: pubClient,
        wallet: client,
    },
});

const tokenBank = getContract({
    address: tokenBankAddress,
    abi: tokenBankAbi.abi as Abi,
    client: {
        public: pubClient,
        wallet: client,
    },
});

async function updateUI() {
    if (!account) return;
    //查看token余额
    const balance = await erc20.read.balanceOf([privateKey]) as bigint;
    //查看存款金额
    const deposit = await tokenBank.read.deposits([privateKey]) as bigint;

    console.log('deposit', deposit);
    console.log('balance', balance);

    balanceSpan.textContent = formatUnits(balance, 18);
    depositSpan.textContent = formatUnits(deposit, 18);
}

//链接钱包
connectBtn.addEventListener('click', async () => {
    if (!window.ethereum) {
        throw new Error('请安装 MetaMask');
    }
    console.log('当前账户1:' ,window.ethereum.request({ method: 'eth_accounts' }));
    const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
    console.log('当前账户2:');
    if (!Array.isArray(accounts) || accounts.length === 0) {
        throw new Error('请连接 MetaMask 钱包');
    }
    console.log('当前账户3:', accounts);
    console.log('当前账户:', accounts[0]);
    account = accounts[0];
    addressSpan.textContent = account;
    await updateUI();
});

//存款
depositBtn.addEventListener('click', async () => {
    if (!account) return;
    const amount = parseUnits('0.01', 18);

    console.log('存款:', amount);
    //授权 1个代币

    console.log('授权地址:', tokenBankAddress);
    await erc20.write.approve([tokenBankAddress, amount]);
    //存款
    await tokenBank.write.deposit([amount]);
    await updateUI();
});

//提取余额
withdrawBtn.addEventListener('click', async () => {
    if (!account) return;
    const amount = parseUnits('0.01', 18);
    await tokenBank.write.withdraw([amount]);
    await updateUI();
});
