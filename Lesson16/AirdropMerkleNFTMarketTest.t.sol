// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {MyTokenPermit} from "../src/MyTokenPermit.sol";
import {MyNFT} from "../src/MyNFT.sol";
import {AirdropMerkleNFTMarket} from "../src/AirdropMerkleNFTMarket.sol";

contract AirdropMerkleNFTMarketTest is Test {
    MyTokenPermit public token;
    MyNFT public nft;
    AirdropMerkleNFTMarket public market;

    // 从 JS 脚本中复制 Merkle Root
    bytes32 public constant MERKLE_ROOT =
        0xa2720bf73072150e787f41f9ca5a9aaf9726d96ee6e786f9920eae0a83b2abed;

    // 测试白名单用户
    address public userWhitelisted = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    // 测试白名单用户私钥
    uint256 public userWhitelistedPk =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    // 测试非白名单用户
    address public userNotWhitelisted =
        0xbef745E4b89216F50f20A77D057604f007C30E86;

    address public msgSender = 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f;

    uint256 public nftPrice = 100 ether;
    uint256 public discountedPrice = nftPrice / 2;

    uint256 public chainId = 31337; // 本地测试链的域ID
    uint256 public userWhitelisted_amount = 100 ether; // 白名单用户的代币余额
    string public constant NFT_URL =
        "https://brown-capitalist-puma-824.mypinata.cloud/ipfs/bafkreihg24rcy32haialclesdvk4aa27fwoxjfbgumlf6jbcb4zlhkuld4";
    function setUp() public {
        vm.startPrank(msgSender);
        // 部署token合约
        token = new MyTokenPermit();
        // 部署NFT合约
        nft = new MyNFT();
        // 部署市场合约
        market = new AirdropMerkleNFTMarket(
            address(nft),
            address(token),
            nftPrice,
            MERKLE_ROOT
        );
        token.transfer(userWhitelisted, userWhitelisted_amount); // 给白名单用户转账100 token

        // Mint NFT 并将其授权给市场合约
        nft.mint(address(market), NFT_URL);
        vm.stopPrank();
    }

    function test_Success_ClaimWithMulticall() public {

        // ----------------------------------------------------------------
        // 步骤 1: 准备该用户的 Merkle Proof (默克尔证明)
        // ----------------------------------------------------------------
        // 这个证明是一组哈希值，用来向合约证明 `userWhitelisted` 这个地址确实存在于最初的白名单列表中。
        // 这些哈希值是从链下的 `generate-merkle.js` 脚本计算得出并复制到这里的。
        bytes32[] memory proof = new bytes32[](4);
        proof[
            0
        ] = 0x00314e565e0574cb412563df634608d76f5c59d9f817e85966100ec1d48005c0;
        proof[
            1
        ] = 0x7e0eefeb2d8740528b8f598997a219669f0842302d3c573e9bb7262be3387e63;
        proof[
            2
        ] = 0x90a5fdc765808e5a2e0d816f52f09820c5f167703ce08d078eb87e2c194c5525;
        proof[
            3
        ] = 0x6957015e8f4c2643fefe1967a4f73da161b800b8cb45e6e469217aac4d0fe5f6;

        // ----------------------------------------------------------------
        // 步骤 2: 准备 EIP-2612 Permit 签名
        // ----------------------------------------------------------------
        // 设置签名的截止时间，通常是当前时间戳加上一个宽裕的时间段（例如1小时）。
        uint256 deadline = block.timestamp + 1 hours;
        // 获取 Token 合约的 EIP-712 域分隔符。这是一个唯一的哈希值，包含了合约名、版本、链ID等信息，
        // 防止一个签名在不同的合约或链上被重放攻击。
        // 注意：这里直接调用token合约的方法
        bytes32 permitDigest = getDomainSeparator();

        // 根据 EIP-712 标准，计算要签名的数据结构 (Permit) 的哈希值。
        // 这清晰地定义了用户到底授权了什么操作（谁授权、授权给谁、授权多少金额等）。
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256(
                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                ),
                userWhitelisted,
                address(market),
                discountedPrice,
                0, // nonce
                deadline
            )
        );

        // 根据 EIP-712 标准，将域分隔符和结构体哈希打包，计算出最终需要被签名的哈希值 (digest)。
        // `\x19\x01` 是一个固定的前缀，确保这个签名不能用于其他目的。
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", permitDigest, structHash)
        );

        // ✨ 使用 Foundry 作弊码 (cheatcode) `vm.sign` 来模拟用户签名。
        // 它使用用户的私钥 (`userWhitelistedPk`) 对我们刚刚创建的 `digest` 进行签名，
        // 并返回签名的三个部分: v, r, s。
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userWhitelistedPk, digest);

        // ----------------------------------------------------------------
        // 步骤 3: 准备 multicall 所需的 calldata
        // ----------------------------------------------------------------
        // `multicall` 函数接收一个字节数组，其中每个元素都是一个完整的函数调用数据 (calldata)。

        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeWithSelector(
            AirdropMerkleNFTMarket.permitPrePay.selector,
            userWhitelisted,
            address(market),
            discountedPrice,
            deadline,
            v,
            r,
            s
        );
        calls[1] = abi.encodeWithSelector(
            AirdropMerkleNFTMarket.claimNFT.selector,
            proof,
            1 // tokenId
        );

        // ----------------------------------------------------------------
        // 步骤 4: 执行交易并验证结果
        // ----------------------------------------------------------------
        // ✨ 使用 Foundry 作弊码 `vm.prank`，告诉 Foundry 下一个调用必须“假装”是由 `userWhitelisted` 发起的。
        // 这会正确设置 `msg.sender`。
        vm.prank(userWhitelisted);
        market.multicall(calls);

        assertEq(nft.ownerOf(1), userWhitelisted, "NFT owner should be user");
        assertEq(
            token.balanceOf(userWhitelisted),
            userWhitelisted_amount - discountedPrice,
            "User token balance is wrong"
        );
        assertEq(
            token.balanceOf(address(market)),
            discountedPrice,
            "Market token balance is wrong"
        );
        assertTrue(
            market.claimed(userWhitelisted),
            "User should be marked as claimed"
        );
    }

    /**
     * @dev 测试用户没有白名单时，是否会失败
     */
    function test_Fail_WhenNotWhitelisted() public {
        bytes32[] memory proof = new bytes32[](0); // 无效的 proof
        bytes[] memory calls = new bytes[](1);
        calls[0] = abi.encodeWithSelector(
            AirdropMerkleNFTMarket.claimNFT.selector,
            proof,
            0
        );

        vm.prank(userNotWhitelisted);
        vm.expectRevert("delegatecall failed");
        market.multicall(calls);
    }

    /**
     * @dev 获取 EIP-712 域分隔符
     * @return bytes32 域分隔符的哈希值
     */
    function getDomainSeparator() public view returns (bytes32) {
        bytes32 eip712DomainTypeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

        // 在这里，你仍然需要代币合约自己的地址
        return
            keccak256(
                abi.encode(
                    eip712DomainTypeHash,
                    keccak256(bytes("yangyang")),
                    keccak256(bytes("1")),
                    chainId,
                    address(token) // 使用token合约的地址
                )
            );
    }
}
