// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MemeFactory.sol";
import "../src/MemeToken.sol";

contract MemeFactoryTest is Test {
    // --- 合约实例 ---
    MemeFactory public factory;
    MemeToken public implementation; // MemeToken 的逻辑合约实例

    // --- 角色/参与者 ---
    // 使用 makeAddr() 替代硬编码地址，更具可读性和避免真实地址冲突
    address public projectOwner = makeAddr("projectOwner"); // 项目方
    address public memeDeployer = makeAddr("memeDeployer"); // Meme发行者
    address public buyer = makeAddr("buyer");             // 购买者
    address public anotherBuyer = makeAddr("anotherBuyer"); // 用于测试的另一个购买者

    // --- 测试参数 ---
    string public constant TEST_SYMBOL = "YY";
    // 明确使用 1e18 表示完整的代币数量，便于计算
    uint256 public constant TEST_MAX_SUPPLY = 1_000_000 * 1e18; // 注意：改为 TEST_MAX_SUPPLY
    // 每次锻造100个代币
    uint256 public constant TEST_PER_MINT = 100 * 1e18;
    // 代币价格
    uint256 public constant TEST_PRICE = 0.01 ether; // 0.01 ETH

    function setUp() public {


        // 给 projectOwner 一些 ETH 来支付部署 gas 费
        vm.deal(projectOwner, 10 ether); 

        // 模拟项目方部署逻辑合约 (MemeToken 的实现合约)
        vm.prank(projectOwner);
        implementation = new MemeToken();

        // 模拟项目方部署工厂合约，并传入实现合约地址
        vm.prank(projectOwner);
        factory = new MemeFactory(address(implementation));

        // 给参与者一些ETH用于支付交易费和铸币费用
        vm.deal(memeDeployer, 10 ether);
        vm.deal(buyer, 10 ether);
        vm.deal(anotherBuyer, 10 ether); // 给另一个购买者发 ETH
    }

    /// --- 测试部署 Meme 代币 ---
    function test_DeployMeme() public {
        vm.prank(memeDeployer);
        // 期望 MemeDeployed 事件被触发
        // tokenAddr 是动态生成的，所以在 vm.expectEmit 中用 address(0) 占位
        vm.expectEmit(false, true, true, true);
        emit MemeFactory.MemeDeployed(address(0), memeDeployer, TEST_SYMBOL, TEST_MAX_SUPPLY); // 确保这里是 TEST_MAX_SUPPLY
        

        address tokenAddr = factory.deployMeme(TEST_SYMBOL, TEST_MAX_SUPPLY, TEST_PER_MINT, TEST_PRICE); // 传入 TEST_MAX_SUPPLY

        MemeToken memeToken = MemeToken(tokenAddr);

        // 验证新创建的Meme代币状态是否正确
        assertEq(memeToken.symbol(), TEST_SYMBOL, "Token symbol mismatch");
        assertEq(memeToken.name(), string.concat("Meme ", TEST_SYMBOL), "Token name mismatch");
        // 修正：使用 maxSupply() 来验证最大供应量
        assertEq(memeToken.maxSupply(), TEST_MAX_SUPPLY, "Token max supply mismatch"); 
        assertEq(memeToken.perMint(), TEST_PER_MINT, "Token per mint mismatch");
        assertEq(memeToken.price(), TEST_PRICE, "Token price mismatch");
        assertEq(memeToken.creator(), memeDeployer, "Token creator mismatch");
        assertEq(memeToken.owner(), address(factory), "Token owner mismatch (should be factory)");
    }

    // /// --- 测试铸币和费用分配 ---
    function test_MintAndFeeDistribution() public {
        // 1. 首先部署Meme代币
        vm.prank(memeDeployer);
        address tokenAddr = factory.deployMeme(TEST_SYMBOL, TEST_MAX_SUPPLY, TEST_PER_MINT, TEST_PRICE);
        MemeToken memeToken = MemeToken(tokenAddr);
        
        // 2. 检查初始ETH余额（在铸币前）
        uint256 projectOwnerInitialBalance = projectOwner.balance;
        uint256 memeDeployerInitialBalance = memeDeployer.balance;
        uint256 buyerInitialBalance = buyer.balance; // 记录买家初始余额

        // 3. 购买者进行铸币
        vm.prank(buyer);
        factory.mintMeme{value: TEST_PRICE}(tokenAddr);

        // 4. 验证购买者的代币余额
        assertEq(memeToken.balanceOf(buyer), TEST_PER_MINT, "Buyer's token balance is incorrect");
        // 修正：使用 minted() 来检查当前已铸造量
        assertEq(memeToken.minted(), TEST_PER_MINT, "Minted supply is incorrect");

        // 5. 验证费用分配
        uint256 projectFee = (TEST_PRICE * factory.PROJECT_FEE_BPS()) / 10000; // 1%
        uint256 deployerFee = TEST_PRICE - projectFee; // 99%

        assertEq(projectOwner.balance, projectOwnerInitialBalance + projectFee, "Project owner should receive 1% fee");
        assertApproxEqAbs(memeDeployer.balance, memeDeployerInitialBalance + deployerFee, 1 wei, "Meme deployer should receive 99% fee"); // 使用约等，因为可能会有微小的gas消耗
        // 检查买家余额是否减少了铸币费用
        assertApproxEqAbs(buyer.balance, buyerInitialBalance - TEST_PRICE, 1 wei, "Buyer's ETH balance should decrease by price");
    }

    /// --- 测试铸币量超过总供应量上限时交易会回滚 ---
    function test_RevertWhenMintExceedsTotalSupply() public {
        // 使用较小的数值以便于测试
        uint256 smallMaxSupply = 100 ether; // 使用 ether
        uint256 smallPerMint = 60 ether;

        vm.prank(memeDeployer);
        address tokenAddr = factory.deployMeme("SMALL", smallMaxSupply, smallPerMint, TEST_PRICE);
        MemeToken memeToken = MemeToken(tokenAddr);

        // 给买家一些 ETH
        vm.deal(buyer, TEST_PRICE * 2); 
        vm.deal(anotherBuyer, TEST_PRICE);

        // 第一次铸币应该成功
        vm.prank(buyer);
        factory.mintMeme{value: TEST_PRICE}(tokenAddr);
        assertEq(memeToken.balanceOf(buyer), smallPerMint, "First mint should succeed");
        assertEq(memeToken.minted(), smallPerMint, "Minted after first mint incorrect");


        // 第二次铸币应该失败，因为 60 + 60 > 100
        vm.prank(anotherBuyer);
        // 期望交易因超出总供应量而回滚，使用正确的 revert 字符串
        vm.expectRevert("MemeToken: Exceeds total supply"); // MemeToken 中的错误信息是 "MemeToken: Exceeds total supply"        
        factory.mintMeme{value: TEST_PRICE}(tokenAddr);

        // 验证代币余额和铸造量没有改变
        assertEq(memeToken.balanceOf(anotherBuyer), 0, "Another buyer should not have tokens");
        assertEq(memeToken.minted(), smallPerMint, "Minted supply should not change after revert");
    }

    // /// --- 测试支付金额不正确时交易会回滚 ---
    function test_RevertOnIncorrectPayment() public {
        vm.prank(memeDeployer);
        address tokenAddr = factory.deployMeme(TEST_SYMBOL, TEST_MAX_SUPPLY, TEST_PER_MINT, TEST_PRICE);

        // 尝试使用不正确的支付金额（低于价格）进行铸币
        vm.prank(buyer);
        // 修正：使用完整的 revert 字符串
        vm.expectRevert("Incorrect payment amount"); 
        factory.mintMeme{value: TEST_PRICE - 1}(tokenAddr);
        
        // 尝试使用不正确的支付金额（高于价格）进行铸币
        vm.prank(buyer);
        // 修正：使用完整的 revert 字符串
        vm.expectRevert("Incorrect payment amount"); 
        factory.mintMeme{value: TEST_PRICE + 1}(tokenAddr);
    }
}