// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MyNFT.sol";
import "./MyERC20V3.sol";

contract NFTMarket is ITokenRecipient {
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
        nft = MyERC721(_nft);
        paymentToken = MyERC20V2(_token);
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


    /// 使用 tokensReceived + transferWithCallback 触发购买
    ///
    function tokensReceived(address from, uint256 amount, bytes calldata data) external override returns(bool){
        require(msg.sender == address(paymentToken), "Invalid token caller");

        //解码data
        uint256 tokenId = abi.decode(data, (uint256));
        Listing memory item = listings[tokenId];

        require(item.price > 0, "NFT not listed");
        require(amount >= item.price, "Insufficient token sent");

        // 转 NFT 给买家
        nft.transferFrom(address(this), from, tokenId);

        // 把资金转给卖家
        require(paymentToken.transfer(item.seller, amount), "Pay to seller failed");

        // 清除 listing
        delete listings[tokenId];

        emit Purchased(from, tokenId, amount);
        return true;
    }

    function buyNFT(uint256 tokenId) external {

        Listing memory item = listings[tokenId];
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