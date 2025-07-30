// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MyTokenPermit.sol";
import "./MyNFT.sol";

contract AirdropMerkleNFTMarket is Ownable {

    //默克尔树
    bytes32 public merkleRoot;
    //NFT合约的实例
    MyNFT public immutable nftContract;
    //代币合约的实例
    MyTokenPermit public immutable tokenContract;
    //NFT的价格
    uint256 public nftPrice;
    //记录每个地址是否已经领取过NFT
    mapping(address => bool) public claimed;
    //NFT被购买时触发
    event NFTClaimed(
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 price
    );

    constructor(
        address _nftAddress,
        address _tokenAddress,
        uint256 _price,
        bytes32 _merkleRoot
    ) Ownable() {
        nftContract = MyNFT(_nftAddress);
        tokenContract = MyTokenPermit(_tokenAddress);
        nftPrice = _price;
        merkleRoot = _merkleRoot;
    }

    /**
     * @dev 它的命名 permitPrePay 暗示了这个函数将使用
     *   permit 机制来预先授权支付。用来购买NFT。
     * @param owner The address of the token owner.这是ERC-20 代币的拥有者地址。这个人将授权将代币从他们的账户转移出去。
     * @param spender The address of the token spender.这是被授权从 owner 账户花费代币的地址。在这个函数中，spender通常是 NFTMarket 合约地址。
     * @param value The amount of tokens to be approved for spending.花费的代币数量。
     * @param deadline The deadline for the permit. 授权的期限。
     * @param v The recovery byte of the signature. 这是 ECDSA 签名的恢复字节。
     * @param r The output of the ECDSA signature. 这是 ECDSA 签名的 r 值。
     * @param s The output of the ECDSA signature. 这是 ECDSA 签名的 s 值。
     * @notice This function allows the owner to pre-authorize the contract 
     */
    function permitPrePay(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(spender == address(this), "Spender must be this contract");
        tokenContract.permit(owner, spender, value, deadline, v, r, s);
    }

    /**
     * @dev 允许用户使用默克尔树证明来领取NFT。
     * @param merkleProof The Merkle proof for the user's address.
     * @param tokenId The ID of the NFT to be claimed.
     */
    function claimNFT(bytes32[] calldata merkleProof, uint256 tokenId) public {
        require(!claimed[msg.sender], "Airdrop already claimed");
        //购买地址的Hash
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, leaf),
            "Invalid Merkle proof; not in whitelist"
        );
        uint256 discountedPrice = nftPrice / 2;
        claimed[msg.sender] = true;
        tokenContract.transferFrom(msg.sender, address(this), discountedPrice);
        nftContract.transferFrom(address(this), msg.sender, tokenId);
        emit NFTClaimed(msg.sender, tokenId, discountedPrice);
    }

    function multicall(bytes[] calldata data) external payable {
        for (uint i = 0; i < data.length; i++) {
            (bool success, ) = address(this).delegatecall(data[i]);
            require(success, "delegatecall failed");
        }
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) public onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    function withdrawTokens() public onlyOwner {
        uint256 balance = tokenContract.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        tokenContract.transfer(owner(), balance);
    }
}
