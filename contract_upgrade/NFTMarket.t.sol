// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {MyNFTUpgrade} from "src/MyNFTUpgrade.sol";
import {NFTMarketV1} from "src/NFTMarketV1.sol";
import {NFTMarketV2} from "src/NFTMarketV2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract NFTMarketTest is Test {
    MyNFTUpgrade public nft;
    NFTMarketV1 public logicV1;
    NFTMarketV2 public logicV2;
    NFTMarketV1 public marketv1; // 通过代理与 V1 通信
    NFTMarketV2 public marketv2; // 通过代理与 V2 通信
    ERC1967Proxy public proxy;

    address public owner = 0x250E9a79B2aFdC11fd9A0C42a855D84E0Aa2ed19;
    uint256 public alicePrivateKey = vm.envUint("PRIVATE_KEY");
    address public alice = 0xbef745E4b89216F50f20A77D057604f007C30E86;
    address public bob = 0x80Ee32778108B44D966923E85eE46D9C5c50dCb7;


    function setUp() public {
        vm.startPrank(owner);

        // 部署 NFT 合约
        nft = new MyNFTUpgrade();
        nft.initialize("TestNFT", "TNFT");

        // 铸造一个 NFT 给 Alice
        nft.mint(alice);
        assertEq(nft.ownerOf(0), alice);

        // 部署 V1 实现合约
        logicV1 = new NFTMarketV1();
        bytes memory initData = abi.encodeWithSelector(
            logicV1.initialize.selector
        );

        proxy = new ERC1967Proxy(address(logicV1), initData);
        // 将 proxy 地址当作市场接口（通过 V2 ABI 使用）
        marketv1 = NFTMarketV1(address(proxy));

        vm.stopPrank();
    }

    function testListAndBuyNFT() public {
        vm.startPrank(alice);

        // Alice 授权市场合约转移她的 NFT
        nft.approve(address(marketv1), 0);

        // Alice 上架 NFT
        marketv1.listNFT(address(nft), 0, 1 ether);
        assertEq(nft.ownerOf(0), address(marketv1));

        vm.stopPrank();

        vm.startPrank(bob);

        // Bob 购买 NFT
        marketv1.buyNFT{value: 1 ether}(address(nft), 0);
        assertEq(nft.ownerOf(0), bob);

        vm.stopPrank();
    }

    function testUpgradeAndListWithSignature() public {
        // 部署 V2 实现合约
        vm.startPrank(owner);
        logicV2 = new NFTMarketV2();

        marketv2 = NFTMarketV2(address(proxy));
        // 升级 proxy 到 V2
        marketv2.upgradeTo(address(logicV2));
        console.log("upgrade to V2 success");

        // Alice 再次 mint 一个新 NFT
        nft.mint(alice); // tokenId = 1
        assertEq(nft.ownerOf(1), alice);
        vm.stopPrank();

        vm.startPrank(alice);
        // Alice 授权市场合约操作她的 NFT（setApproveForAll）
        nft.setApprovalForAll(address(marketv2), true);

        // 准备签名数据
        uint256 price = 1 ether;
        bytes32 messageHash = keccak256(
            abi.encodePacked(alice, address(nft), uint256(1), price)
        );
        bytes32 ethSigned = ECDSA.toEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, ethSigned);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Alice 使用签名上架 NFT
        marketv2.listNFTWithSignature(address(nft), uint256(1), price, signature);
        assertEq(nft.ownerOf(1), address(marketv2));

        vm.stopPrank();

        vm.startPrank(bob);
        marketv2.buyNFT{value: 1 ether}(address(nft), 1);
        assertEq(nft.ownerOf(1), bob);
        vm.stopPrank();
    }
}
