// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MyNFT.sol";
import "./MyTokenPermit.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract NFTMarketPermit is ITokenRecipient {
    using ECDSA for bytes32;

    MyTokenPermit public myTokenPermit;
    MyNFT public myNFT;

    struct Listing {
        address seller;
        uint256 price;
    }

    // tokenId => Listing
    mapping(uint256 => Listing) public listings;

    address public signer;

    event Listed(
        address indexed seller,
        uint256 indexed tokenId,
        uint256 price
    );
    event Purchased(
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 price
    );

    constructor(address _nft, address _token, address _signer) {
        myNFT = MyNFT(_nft);
        myTokenPermit = MyTokenPermit(_token);
        signer = _signer;
    }

    /// 上架 NFT
    function list(uint256 tokenId, uint256 price) external {
        //验证tokenID是否属于自己
        require(myNFT.ownerOf(tokenId) == msg.sender, "Not owner");
        //上架的价格必须大于0
        require(price > 0, "Price must be positive");

        myNFT.transferFrom(msg.sender, address(this), tokenId);
        listings[tokenId] = Listing(msg.sender, price);

        emit Listed(msg.sender, tokenId, price);
    }

    function buyNFT(uint256 tokenId) external {
        Listing memory item = listings[tokenId];
        require(msg.sender != address(0), "error address");
        require(item.seller != msg.sender, "NFT not owner");
        require(item.price > 0, "NFT not listed");

        // 用户授权token合约，使用 transferFrom 支付 token
        bool success = myTokenPermit.transferFrom(
            msg.sender,
            item.seller,
            item.price
        );
        require(success, "Token transfer failed");

        // NFT 转给买家
        myNFT.transferFrom(address(this), msg.sender, tokenId);

        // 删除 listing
        delete listings[tokenId];

        emit Purchased(msg.sender, tokenId, item.price);
    }

    function permitBuy(uint256 tokenId, bytes calldata signature) external {
        Listing memory listing = listings[tokenId];
        // 确保 NFT 已上架
        require(listing.price > 0, "Not listed");

        // 构造签名的消息哈希: hash(msg.sender, tokenId)
        bytes32 message = keccak256(abi.encodePacked(msg.sender, tokenId));
        // 构造 EIP-191 格式的以太坊签名哈希
        bytes32 ethSignedMessage = message.toEthSignedMessageHash();

        // 校验签名是否由 signer 签发
        require(
            ethSignedMessage.recover(signature) == signer,
            "Invalid permit"
        );

        // 转移token给卖家
        bool success = myTokenPermit.transferFrom(
            msg.sender,
            listing.seller,
            listing.price
        );
        require(success, "Token transfer failed");

        // 将 NFT 转给买家
        myNFT.transferFrom(address(this), msg.sender, tokenId);
        // 删除 listing
        delete listings[tokenId];

        emit Purchased(msg.sender, tokenId, listing.price);
    }

    // 回调函数：用户通过 transferWithCallback 存入时自动触发
    function tokensReceived(
        address from,
        uint256 amount,
        bytes calldata data
    ) external override returns (bool) {
        require(
            msg.sender == address(myTokenPermit),
            "MyERC20V3: invalid token"
        );

        uint256 tokenId = abi.decode(data, (uint256));
        require(
            amount >= listings[tokenId].price,
            "MyERC20V3: amount must than price"
        );
        // NFT 转给买家
        myNFT.transferFrom(address(this), from, tokenId);
        // 删除 listing
        delete listings[tokenId];

        emit Purchased(from, tokenId, listings[tokenId].price);
        return true;
    }
}
