import { createPublicClient, webSocket, parseAbi } from 'viem';
import { sepolia } from 'viem/chains';

// 部署的合约地址
const marketAddress = '0x31A7fB373d99373538216BC52a7C3009b42Db1Af';

// Infura WebSocket RPC
const wsUrl = 'wss://sepolia.infura.io/ws/v3/ec27bdf38453436683b5f6438a97741f';

const client = createPublicClient({
  chain: sepolia,
  transport: webSocket(wsUrl),
});

// ABI 事件格式（注意：这里只包含事件）
const abi = parseAbi([
  'event Listed(address indexed seller, uint256 indexed tokenId, uint256 price)',
  'event Purchased(address indexed buyer, uint256 indexed tokenId, uint256 price)',
]);



// 🎯 监听 NFT 上架
client.watchContractEvent({
  address: marketAddress,
  abi,
  eventName: 'Listed',
  onLogs: (logs) => {
    logs.forEach(log => {
      console.log('NFT 上架事件');
      console.log(`卖家: ${log.args.seller}`);
      console.log(`TokenID: ${log.args.tokenId}`);
      console.log(`价格: ${log.args.price} Token`);
      console.log('----------------------------------');
    });
  },
});

// 🎯 监听 NFT 购买
client.watchContractEvent({
  address: marketAddress,
  abi,
  eventName: 'Purchased',
  onLogs: (logs) => {
    logs.forEach(log => {
      console.log('NFT 被购买');
      console.log(`买家: ${log.args.buyer}`);
      console.log(`TokenID: ${log.args.tokenId}`);
      console.log(`价格: ${log.args.price} Token`);
      console.log('----------------------------------');
    });
  },
});
