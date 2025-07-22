// src/lib/contracts.ts
import erc20Abi from './abis/MyERC20V3.json';
import nftAbi from './abis/MyNFT.json';
import marketAbi from './abis/NFTMarket.json';
import { useWalletClient, useAccount } from 'wagmi';
import { getContract, parseUnits } from 'viem';

const NFT_ADDRESS = '0xBd32023CE8915Ec302324C0e3Ba97cD5344BfEEd';
const TOKEN_ADDRESS = '0x8F9Db5C035cdada3a125De9A0A0B80427bdafD0b';
const MARKET_ADDRESS = '0x31A7fB373d99373538216BC52a7C3009b42Db1Af';

const token_abi = erc20Abi.abi; 
const nft_abi = nftAbi.abi; 
const market_abi = marketAbi.abi; 
export function useMarketActions() {
  const { data: walletClient } = useWalletClient();
  const { address } = useAccount();

  const erc20 = getContract({
    address: TOKEN_ADDRESS,
    abi: token_abi,
    walletClient,
  });

  const nft = getContract({
    address: NFT_ADDRESS,
    abi: nft_abi,
    walletClient,
  });

  const market = getContract({
    address: MARKET_ADDRESS,
    abi: market_abi,
    walletClient,
  });

  return {
    address,
    approveToken: async (amount: string) => {
      const value = parseUnits(amount, 18);
      return await erc20.write.approve([MARKET_ADDRESS, value]);
    },
    approveNFT: async (tokenId: bigint) => {
      return await nft.write.approve([MARKET_ADDRESS, tokenId]);
    },
    listNFT: async (tokenId: bigint, price: string) => {
      const value = parseUnits(price, 18);
      return await market.write.list([ tokenId, value]);
    },
    buyNFT: async (tokenId: bigint) => {
      return await market.write.buyNFT([tokenId]);
    },
  };
}
