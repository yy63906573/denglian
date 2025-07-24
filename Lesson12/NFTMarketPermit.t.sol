// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {NFTMarketPermit} from "../src/NFTMarketPermit.sol";
import {MyTokenPermit} from "../src/MyTokenPermit.sol";
import {MyNFT} from "../src/MyNFT.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract NFTMarketTest is Test {
    NFTMarketPermit public nftMarketPermit;
    MyNFT public nft;
    MyTokenPermit public myTokenPermit;
    uint256 public tokenId;
    //address admin = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    address public seller = address(0xbef745E4b89216F50f20A77D057604f007C30E86);
    address public buyer = address(0x250E9a79B2aFdC11fd9A0C42a855D84E0Aa2ed19);

    // 签名者地址 就是seller
    uint256 public signerPrivateKey =
        0x47c972973e1260e754a89977e5d678bac9681c0902391b79fcdfab6ae68aeed4;

    // address _nft = address(0xBd32023CE8915Ec302324C0e3Ba97cD5344BfEEd);
    // address _myTokenPermit =
    //     address(0x1b9001f79728fa420F1dC0b56152AFCdfB04d173);

    function setUp() public {
        //0xbef745E4b89216F50f20A77D057604f007C30E86 授权 0x250E9a79B2aFdC11fd9A0C42a855D84E0Aa2ed19 buyer 购买 ，只是为了sepolia测试
        getHash(address(0x250E9a79B2aFdC11fd9A0C42a855D84E0Aa2ed19), 1);
        vm.startPrank(seller);
        nft = new MyNFT();

        myTokenPermit = new MyTokenPermit();
        nftMarketPermit = new NFTMarketPermit(
            address(nft),
            address(myTokenPermit),
            seller
        );

        tokenId = nft.mint(
            seller,
            "https://brown-capitalist-puma-824.mypinata.cloud/ipfs/bafkreihg24rcy32haialclesdvk4aa27fwoxjfbgumlf6jbcb4zlhkuld4"
        );

        //seller给byer 200 token
        myTokenPermit.transfer(buyer, 200 ether);

        // seller 授权 Market 转 NFT
        nft.approve(address(nftMarketPermit), tokenId);

        vm.stopPrank();

        // buyer 授权 Market 使用 100token
        vm.prank(buyer);
        myTokenPermit.approve(address(nftMarketPermit), 100 ether);
    }

    function testBuyNFT() public {
        vm.prank(seller);
        nftMarketPermit.list(tokenId, 100 ether);

        bytes memory signature = getHash(buyer, tokenId);

        uint256 balanceBefore = myTokenPermit.balanceOf(seller);
        console.log("Seller balance before buying NFT: :", balanceBefore);

        vm.expectEmit(true, true, false, true);
        emit NFTMarketPermit.Purchased(buyer, tokenId, 100 ether);
        vm.prank(buyer);
        nftMarketPermit.permitBuy(tokenId, signature);

        uint256 balanceAfter = myTokenPermit.balanceOf(seller);
        console.log("Seller balance after buying NFT: ", balanceAfter);

        address owner = nft.ownerOf(tokenId);
        assertEq(owner, buyer, "NFT ownership not transferred");
        console.log("buyer has NFT is : ", tokenId);
    }

    function getHash(
        address _buyer,
        uint256 _tokenId
    ) public returns (bytes memory) {
        // 哈希结构体或内容
        bytes32 messagehash = keccak256(abi.encodePacked(_buyer, _tokenId));
        // 构造 EIP-191 兼容签名哈希
        bytes32 ethSignedMessage = ECDSA.toEthSignedMessageHash(messagehash);
        // 用私钥签名
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            signerPrivateKey,
            ethSignedMessage
        );
        // 打包成 signature
        bytes memory _signature = abi.encodePacked(r, s, v);

        // console.log("signature: ", _signature);
        console.logBytes(_signature);
        return _signature;
    }
}
