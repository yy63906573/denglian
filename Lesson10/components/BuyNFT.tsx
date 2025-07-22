import { useState } from 'react';
import { useMarketActions } from '../lib/contracts';

export default function BuyNFT() {
    const [tokenId, setTokenId] = useState('');
    const { approveToken, buyNFT } = useMarketActions();

    const handleBuy = async () => {
        const id = BigInt(tokenId);
        await approveToken('1'); // 这里假设价格是 1 Token
        await buyNFT(id);
        alert('购买成功');
    };

    return (
        <div>
            <h2>购买 NFT</h2>
            <input value={tokenId} onChange={e => setTokenId(e.target.value)} placeholder="NFT TokenId" />
            <button onClick={handleBuy}>购买</button>
        </div>
    );
}
