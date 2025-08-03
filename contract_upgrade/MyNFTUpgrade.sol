// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice 引入 OpenZeppelin 的可升级合约库
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @title 一个可升级的 ERC721 合约（用于 NFT 铸造）
contract MyNFTUpgrade is
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    uint256 public nextTokenId;

    /// @notice 初始化函数，代替构造函数（只能调用一次）
    /// @param name NFT 名称
    /// @param symbol NFT 符号
    function initialize(
        string memory name,
        string memory symbol
    ) public initializer {
        __ERC721_init(name, symbol); // 初始化 ERC721
        __Ownable_init(); // 初始化 Ownable（管理员）
        __UUPSUpgradeable_init(); // 初始化 UUPS 升级支持
    }

    /// @notice 只有管理员可以授权升级合约
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /// @notice 铸造一个新的 NFT 给指定地址
    function mint(address to) external onlyOwner {
        _safeMint(to, nextTokenId);
        nextTokenId++;
    }
}
