// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MyNFT.sol";
import "./MyERC20Token.sol";

contract NFTMarket {
    MyERC20V3 public paymentToken;
    MyNFT public nft;

    struct Listing {
        address seller;
        uint256 price;
    }

    // tokenId => Listing
    mapping(uint256 => Listing) public listings;

    event Listed(address indexed seller, uint256 indexed tokenId, uint256 price);
    event Purchased(address indexed buyer, uint256 indexed tokenId, uint256 price);

    constructor(address _nft, address _token) {
        nft = MyNFT(_nft);
        paymentToken = MyERC20V3(_token);
    }

    /// 上架 NFT
    function list(uint256 tokenId, uint256 price) external {
        //验证tokenID是否属于自己
        require(nft.ownerOf(tokenId) == msg.sender, "Not owner");
        //上架的价格必须大于0
        require(price > 0, "Price must be positive");

        nft.transferFrom(msg.sender, address(this), tokenId);
        listings[tokenId] = Listing(msg.sender,price);

        emit Listed(msg.sender,tokenId,  price);
    }

    function buyNFT(uint256 tokenId) external {

        Listing memory item = listings[tokenId];
        require(msg.sender != address(0), "error address");
        require(item.seller != msg.sender, "NFT not owner");
        require(item.price > 0, "NFT not listed");

        // 用户授权token合约，使用 transferFrom 支付 token
        bool success = paymentToken.transferFrom(msg.sender, item.seller, item.price);
        require(success, "Token transfer failed");

        // NFT 转给买家
        nft.transferFrom(address(this), msg.sender, tokenId);

        // 删除 listing
        delete listings[tokenId];

        emit Purchased(msg.sender, tokenId, item.price);
    }

     
}