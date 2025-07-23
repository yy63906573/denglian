import { createWalletClient, http, parseUnits, createPublicClient, parseAbi } from 'viem'
import { privateKeyToAccount } from 'viem/accounts'
import { sepolia } from 'viem/chains'
import readline from 'readline'

// ERC20 ABI 只需要 balanceOf 和 transfer 方法
const erc20Abi = parseAbi([
    'function balanceOf(address) view returns (uint256)',
    'function transfer(address,uint256) returns (bool)'
])

// 示例：USDC on Sepolia（你也可以换成你自己的 token 地址）
const TOKEN_ADDRESS = '0x8F9Db5C035cdada3a125De9A0A0B80427bdafD0b' // 替换为你要操作的 ERC20 合约地址

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
})

function ask(query) {
    return new Promise(resolve => rl.question(query, resolve))
}

async function main() {
    console.log('🪙 命令行钱包 - Viem 版本')

    let choice = await ask('你想要 (1) 创建新钱包 还是 (2) 输入已有私钥？ 输入1或2：')

    let account
    while(true){
        if(choice === '1') {
            let privateKey = generatePrivateKey();
            account = privateKeyToAccount(privateKey)
            console.log('✅ 新钱包生成')
            console.log('地址：', account.address)
            console.log('私钥（请保存好）：', privateKey)
            break;
        } else if (choice === '2') {
            const pk = await ask('请输入私钥（以 0x 开头）：')
            account = privateKeyToAccount(pk.trim())
            console.log('地址：', account.address)
            break;
        } else if (choice === 'exit') {
            console.log('退出')
            process.exit(1)
        } else{
            console.log('无效选择，请输入 1 或 2')
            choice = await ask('你想要 (1) 创建新钱包 还是 (2) 输入已有私钥？ 输入1或2：')
            continue
        }
    }


const publicClient = createPublicClient({
    chain: sepolia,
    transport: http('https://sepolia.infura.io/v3/ec27bdf38453436683b5f6438a97741f')
})

const walletClient = createWalletClient({
    account,
    chain: sepolia,
    transport: http('https://sepolia.infura.io/v3/ec27bdf38453436683b5f6438a97741f')
})

const erc20 = {
    address: TOKEN_ADDRESS,
    abi: erc20Abi
}

// 查询余额
const balance = await publicClient.readContract({
    ...erc20,
    functionName: 'balanceOf',
    args: [account.address]
})

console.log(`当前 ERC20 余额: ${balance}（单位最小）`)

const to = await ask('请输入接收方地址: ')
const amount = await ask('请输入转账金额（整数，单位: Token 的最小单位）: ')

// 构建交易
const hash = await walletClient.writeContract({
    ...erc20,
    functionName: 'transfer',
    args: [to.trim(), BigInt(amount)],
    account
})

console.log('📤 交易已发送，hash：', hash)
rl.close()
}

// 简单生成 32 字节私钥
function generatePrivateKey() {
    const bytes = crypto.getRandomValues(new Uint8Array(32))
    return '0x' + [...bytes].map(x => x.toString(16).padStart(2, '0')).join('')
}

main()
