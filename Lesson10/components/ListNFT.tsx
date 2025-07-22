import { useState } from 'react';
import { useMarketActions } from '../lib/contracts';

export default function ListNFT() {
  const [tokenId, setTokenId] = useState('');
  const [price, setPrice] = useState('');
  const { approveNFT, listNFT } = useMarketActions();

  const handleList = async () => {
    const id = BigInt(tokenId);
    await approveNFT(id);
    await listNFT(id, price);
    alert('上架成功');
  };

  return (
    <div>
      <h2>上架 NFT</h2>
      <input value={tokenId} onChange={e => setTokenId(e.target.value)} placeholder="NFT TokenId" />
      <input value={price} onChange={e => setPrice(e.target.value)} placeholder="价格（ERC20）" />
      <button onClick={handleList}>上架</button>
    </div>
  );
}
