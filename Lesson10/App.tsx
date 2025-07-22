import ListNFT from './components/ListNFT';
import BuyNFT from './components/BuyNFT';

export default function App() {
  return (
    <div>
      <h1>NFTMarket</h1>
      <ListNFT />
      <hr />
      <BuyNFT />
    </div>
  );
}