// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice 引入部署库与合约接口
import "forge-std/Script.sol";
import {MyNFTUpgrade} from "src/MyNFTUpgrade.sol";
import {NFTMarketV1} from "src/NFTMarketV1.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
contract DeployNFTMarket is Script {
    function run() external {
        // 加载部署私钥（从 .env 或环境变量中获取）
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // 开始广播交易
        vm.startBroadcast(deployerPrivateKey);

        // 1️部署可升级的 ERC721 合约
        MyNFTUpgrade nft = new MyNFTUpgrade();
        nft.initialize("MyNFT", "MNFT");
        console.log("Deployed NFT-contract: ", address(nft));

        // 2️部署 NFTMarketV1 实现合约
        NFTMarketV1 marketImpl = new NFTMarketV1();
        console.log("Deployed NFTMarketV1-contract: ", address(marketImpl));

        // 3️初始化 calldata
        bytes memory initData = abi.encodeWithSelector(
            marketImpl.initialize.selector
        );

        // 4️创建代理合约，代理到 V1 实现合约
        ERC1967Proxy proxy = new ERC1967Proxy(address(marketImpl), initData);
        console.log("Deployed UUPSProxy-contract: ", address(proxy));

        vm.stopBroadcast();
    }
}
