// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/NFTMarket.sol";
import "../src/MyNFT.sol";
import "../src/MyERC20Token.sol";

contract NFTMarketTest is Test {
    MyNFT public nft;
    MyERC20V3 public token;
    NFTMarket public market;

    address admin = address(0xbef745E4b89216F50f20A77D057604f007C30E86);
    address buyer = address(0x250E9a79B2aFdC11fd9A0C42a855D84E0Aa2ed19);
    address testUser = address(0x957BbD24fCB9d7E78F57Ec1C7CFf1BD6906a3C51);
    address seller = address(0x80Ee32778108B44D966923E85eE46D9C5c50dCb7);
    uint256 tokenId;

    function setUp() public {
        nft = new MyNFT("kekexil", "keke");
        vm.prank(admin);
        token = new MyERC20V3();
        market = new NFTMarket(address(nft), address(token));

        vm.prank(seller);
        tokenId = nft.mint(seller, "https://brown-capitalist-puma-824.mypinata.cloud/ipfs/bafkreihg24rcy32haialclesdvk4aa27fwoxjfbgumlf6jbcb4zlhkuld4");

        // seller 授权 Market 转 NFT
        vm.prank(seller);
        nft.approve(address(market), tokenId);

        //给byer 1000 token
        vm.prank(admin);
        token.transfer(buyer, 1000 ether);

        // buyer 授权 Market 使用 100token
        vm.prank(buyer);
        token.approve(address(market), 100 ether);


    }

    //测试用户上架 NFT 成功
    function testSuccessList() public {
        vm.prank(seller);
        token.approve(address(market), 100 ether);

        vm.prank(seller);

        vm.expectEmit(true, true, false, true);
        emit NFTMarket.Listed(seller, tokenId, 100 ether);
        market.list(tokenId, 100 ether);

       

        (address _seller, uint256 _price) = market.listings(tokenId);
        assertEq(_seller, seller);
        assertEq(_price, 100 ether);
    }

    //测试用户不是卖家时上架失败
    function testListNotOwnerRevert() public {
        vm.prank(testUser);
        vm.expectRevert("Not owner");
        market.list(tokenId, 100 ether);
    }

    //测试用户上架 NFT 价格为0时失败
    function testListZeroPriceRevert() public {
        vm.prank(seller);
        vm.expectRevert("Price must be positive");
        market.list(tokenId, 0);
    }

    // 测试用户购买 NFT 成功
    function testBuyNFTSuccess() public {
        vm.prank(seller);
        market.list(tokenId, 100 ether);

        uint256 balanceBefore = token.balanceOf(seller);
        console.log("balanceBefore: ", balanceBefore);


        vm.expectEmit(true, true, false, true);
        emit NFTMarket.Purchased(buyer, tokenId, 100 ether);

        vm.prank(buyer);
        market.buyNFT(tokenId);

        assertEq(nft.ownerOf(tokenId), buyer);
        assertEq(token.balanceOf(seller), balanceBefore + 100 ether);
    }

        // 测试自己购买自己的 NFT 失败
    function testBuyOwnNFTRevert() public {
        vm.prank(seller);
        market.list(tokenId, 100 ether);

        vm.expectRevert("NFT not owner"); // 默认 revert（可自定义信息）
        vm.prank(seller);
        market.buyNFT(tokenId);
    }

    // 测试两次购买 NFT 失败
    function testBuyTwiceRevert() public {
        vm.prank(seller);
        market.list(tokenId, 100 ether);

        vm.expectEmit(true, true, false, true);
        emit NFTMarket.Purchased(buyer, tokenId, 100 ether);
        vm.prank(buyer);
        market.buyNFT(tokenId);

        vm.prank(buyer);
        vm.expectRevert("NFT not listed");
        market.buyNFT(tokenId);
    }

    // 测试购买 NFT 时余额不足失败
    function testBuyWithInsufficientToken() public {
        vm.prank(seller);
        market.list(tokenId, 100 ether);


        vm.prank(buyer);
        token.approve(address(market), 50 ether);

        vm.expectRevert("ERC20: token transfer amount exceeds allowance");
        vm.prank(buyer);
        market.buyNFT(tokenId);
    }


    // 测试购买 NFT 时余额过多失败
    function testBuyWithExcessBalance()  public {
        vm.prank(seller);
        market.list(tokenId, 100 ether);

        uint256 balance_Before = token.balanceOf(buyer);
        assertEq(balance_Before, 1000 ether);

        vm.prank(buyer);
        token.approve(address(market), 200 ether);

        vm.expectEmit(true, true, false, true);
        emit NFTMarket.Purchased(buyer, tokenId, 100 ether);

        vm.prank(buyer);
        market.buyNFT(tokenId);
        

        uint256 blance_Buy = token.balanceOf(buyer);
        assertEq(blance_Buy, 900 ether);
    }

// Fuzz测试 随机测试0.01 ether 到 10000 ether 的价格
     function testFuzzBuyNFT_price(uint256 price) public {
        price = bound(price, 0.01 ether, 10000 ether);

        vm.prank(seller);
        market.list(tokenId, price);
         (address sellerAddr, uint256 listingPrice) = market.listings(tokenId);
        assertEq(price, listingPrice);
        assertEq(sellerAddr, seller);

    }

    function testFuzzBuyNFT_address(address randomBuyer) public {

        vm.assume(randomBuyer != address(0));
        vm.assume(randomBuyer != address(this));
        vm.prank(seller);
        market.list(tokenId, 100 ether);


         //给byer 1000 token
        vm.prank(admin);
        token.transfer(randomBuyer, 1000 ether);

        // buyer 授权 Market 使用 100token
        vm.prank(randomBuyer);
        token.approve(address(market), 100 ether);

        //randomBuyer购买
        vm.prank(randomBuyer);
        market.buyNFT(tokenId);

        // 验证 NFT 归属权变化
        assertEq(nft.ownerOf(tokenId), randomBuyer);

    }

    //NFTMarket 合约不应该持有任何代币
    function invariantMarketShouldNotHoldToken() public view {
        uint256 balance = token.balanceOf(address(market));
        assertEq(balance, 123);
    }
}