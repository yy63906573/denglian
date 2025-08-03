// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice 引入 OpenZeppelin 的模块化合约组件
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title 一个基础版 NFT 市场合约（可升级）
contract NFTMarketV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    /// @notice 上架信息结构体：卖家地址与价格
    struct Listing {
        address seller;
        uint256 price;
    }

    /// @notice 记录每个 NFT 的上架信息：nft 合约地址 => tokenId => Listing
    mapping(address => mapping(uint256 => Listing)) public listings;

    /// @notice 初始化函数，代替构造函数
    function initialize() public initializer {
        __Ownable_init();            // 初始化管理员
        __UUPSUpgradeable_init();    // 启用 UUPS 升级模式
    }

    /// @notice 授权合约升级，只有合约管理员可以执行
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @notice 上架 NFT（需先 Approve 给市场合约）
    /// @param nft NFT 合约地址
    /// @param tokenId 要上架的 tokenId
    /// @param price 上架价格（单位：wei）
    function listNFT(address nft, uint256 tokenId, uint256 price) external {
        require(price > 0, "price must bu more than 0");

        // 将 NFT 从卖家转移到市场合约
        IERC721(nft).transferFrom(msg.sender, address(this), tokenId);

        // 记录上架信息
        listings[nft][tokenId] = Listing({
            seller: msg.sender,
            price: price
        });
    }

    /// @notice 购买 NFT
    /// @param nft NFT 合约地址
    /// @param tokenId 要购买的 tokenId
    function buyNFT(address nft, uint256 tokenId) external payable {
        Listing memory listing = listings[nft][tokenId];
        require(listing.price > 0, "NFT not listed");
        require(msg.value >= listing.price, "enough ETH sent");

        // 删除上架记录
        delete listings[nft][tokenId];

        // 支付给卖家
        payable(listing.seller).transfer(listing.price);

        // 将 NFT 转移给买家
        IERC721(nft).transferFrom(address(this), msg.sender, tokenId);
    }
}
