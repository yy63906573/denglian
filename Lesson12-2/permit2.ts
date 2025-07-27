import { createWalletClient, createPublicClient, parseUnits, custom } from 'viem';
import { sepolia } from 'viem/chains';

const token = '0x1b9001f79728fa420F1dC0b56152AFCdfB04d173';
const tokenBank = '0x643E9554ef530F208FFa0839c157620271072862';
const permit2Add = '0x000000000022D473030F116dDEE9F6B43aC78BA3';

const erc20Abi = [
    {
        name: 'approve', type: 'function', stateMutability: 'nonpayable', inputs: [
            { name: 'spender', type: 'address' },
            { name: 'amount', type: 'uint256' }
        ], outputs: []
    },
    {
        name: 'balanceOf', type: 'function', stateMutability: 'view', inputs: [
            { name: 'owner', type: 'address' }
        ], outputs: [{ name: '', type: 'uint256' }]
    }
];

const tokenBankAbi = [
    {
        name: 'depositWithPermit2',
        type: 'function',
        stateMutability: 'nonpayable',
        inputs: [
            {
                name: 'permit',
                type: 'tuple',
                components: [
                    {
                        name: 'permitted', type: 'tuple', components: [
                            { name: 'token', type: 'address' },
                            { name: 'amount', type: 'uint160' }
                        ]
                    },
                    { name: 'nonce', type: 'uint256' },
                    { name: 'deadline', type: 'uint256' }
                ]
            },
            {
                name: 'transferDetails',
                type: 'tuple',
                components: [
                    { name: 'to', type: 'address' },
                    { name: 'requestedAmount', type: 'uint160' }
                ]
            },
            { name: 'owner', type: 'address' },
            { name: 'signature', type: 'bytes' }
        ],
        outputs: []
    }
];

const client = createWalletClient({
    chain: sepolia,
    transport: custom(window.ethereum)
});

const publicClient = createPublicClient({
    chain: sepolia,
    transport: custom(window.ethereum)
});

let account;

async function connect() {
    [account] = await window.ethereum.request({ method: 'eth_requestAccounts' });
    document.getElementById('wallet').innerText = `钱包地址：${account}`;
    refreshBalance();
}

async function refreshBalance() {
    const balance = await publicClient.readContract({
        address: token,
        abi: erc20Abi,
        functionName: 'balanceOf',
        args: [account]
    });
    const balanceInNumber = Number(balance) / 1e18;
    document.getElementById('balance').innerText = `余额：${balanceInNumber} TOKEN`;
}

document.getElementById('approve').onclick = async () => {
    await client.writeContract({
        address: token,
        abi: erc20Abi,
        functionName: 'approve',
        args: [permit2Add, BigInt(2 ** 18 * 1000)],
        account
    });
    alert('已授权 Permit2');
};

document.getElementById('deposit').onclick = async () => {
    const rawAmount = document.getElementById('amount').value;
    if (!rawAmount || isNaN(Number(rawAmount)) || Number(rawAmount) <= 0) {
        alert('请输入有效的存款金额');
        return;
    }

    const amount = parseUnits(rawAmount, 18);
    const deadline = Math.floor(Date.now() / 1000) + 3600;

    //   const nonce = await publicClient.readContract({
    //     address: permit2Add,
    //     abi: [{
    //       name: 'nonce',
    //       type: 'function',
    //       stateMutability: 'view',
    //       inputs: [
    //         { name: 'owner', type: 'address' },
    //         { name: 'token', type: 'address' },
    //         { name: 'spender', type: 'address' }
    //       ],
    //       outputs: [{ name: '', type: 'uint256' }]
    //     }],
    //     functionName: 'nonce',
    //     args: [account, token, tokenBank]
    //   });
    const nonce = 0;
    const domain = {
        name: 'Permit2',
        chainId: 11155111,
        verifyingContract: permit2Add
    };


    const types = {
        PermitTransferFrom: [
            { name: 'permitted', type: 'TokenPermissions' },
            { name: 'nonce', type: 'uint256' },
            { name: 'deadline', type: 'uint256' }
        ],
        TokenPermissions: [
            { name: 'token', type: 'address' },
            { name: 'amount', type: 'uint160' }
        ]
    };

    const message = {
        permitted: {
            token: token,
            amount: amount
        },
        nonce: nonce,
        deadline: deadline
    };


    const signature = await client.signTypedData({
        account,
        domain,
        types,
        primaryType: 'PermitTransferFrom',
        message
    });

    await client.writeContract({
        address: tokenBank,
        abi: tokenBankAbi,
        functionName: 'depositWithPermit2',
        args: [
            message,
            {
                to: tokenBank,
                requestedAmount: amount
            },
            account,
            signature
        ],
        account
    });

    alert('存款成功！');
    await refreshBalance();
};

connect();
