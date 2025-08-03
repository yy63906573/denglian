// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice 引入 V1 合约
import "./NFTMarketV1.sol";

/// @notice 用于签名恢复的工具库
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

/// @title NFT 市场升级版（V2）：新增签名上架功能
contract NFTMarketV2 is NFTMarketV1,ERC721Holder  {
    using ECDSA for bytes32;

    /// @notice 通过签名上架 NFT（不再需要每次手动 approve）
    /// @param nft NFT 合约地址
    /// @param tokenId NFT 的 ID
    /// @param price 上架价格（单位：wei）
    /// @param signature 卖家离线签名的数据
    function listNFTWithSignature(
        address nft,
        uint256 tokenId,
        uint256 price,
        bytes memory signature
    ) external {
        require(price > 0, "price must be more than 0");

        // 构造签名的原始消息 hash（不包含 eth_sign 前缀）
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, nft, tokenId, price));

        // 转换为 EIP-191 兼容格式的以太坊签名（用于 eth_sign）
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();

        // 恢复签名地址
        address signer = ethSignedMessageHash.recover(signature);

        // 验证签名必须来自 msg.sender（卖家）
        require(signer == msg.sender, "singature not valid");

        // 要求用户已经 setApprovalForAll 给市场合约
        require(
            IERC721(nft).isApprovedForAll(msg.sender, address(this)),
            "seller must setApprovalForAll"
        );

        // 将 NFT 从卖家转移到市场
        IERC721(nft).safeTransferFrom(msg.sender, address(this), tokenId);

        // 记录上架信息
        listings[nft][tokenId] = Listing({
            seller: msg.sender,
            price: price
        });
    }
}
