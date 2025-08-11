// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@v2-core/interfaces/IUniswapV2Router02.sol";
import "@v2-core/interfaces/IUniswapV2Factory.sol";
import "@v2-core/libraries/UniswapV2Library.sol";
import "@v2-core/UniswapV2Factory.sol";
import "@v2-core/UniswapV2Router02.sol";
import "@v2-core/UniswapV2Pair.sol";
import "@v2-periphery/test/WETH9.sol";
import "src/MemeFactory.sol";
import "src/MemeToken.sol";

contract MemeFactoryTest is Test {
    // --- 合约实例 ---
    MemeFactory public factory;
    MemeToken public implementation;
    IUniswapV2Router02 public uniswapRouter;
    IUniswapV2Factory public uniswapFactory;
    WETH9 public WETH;

    // --- 角色/参与者 ---
    address public projectOwner = makeAddr("projectOwner");
    address public memeDeployer = makeAddr("memeDeployer");
    address public buyer = makeAddr("buyer");
    address public anotherBuyer = makeAddr("anotherBuyer");

    // --- 测试参数 ---
    string public constant TEST_SYMBOL = "YY";
    uint256 public constant TEST_MAX_SUPPLY = 1_000_000 * 1e18;
    uint256 public constant TEST_PER_MINT = 100 * 1e18;
    uint256 public constant TEST_PRICE = 10 ether;

    function setUp() public {
        vm.deal(projectOwner, 10 ether);
        vm.prank(projectOwner);
        implementation = new MemeToken();

        // 部署 Uniswap V2 模拟合约
        vm.prank(projectOwner);
        uniswapFactory = IUniswapV2Factory(new UniswapV2Factory(address(this)));
        vm.prank(projectOwner);
        WETH = new WETH9();
        vm.prank(projectOwner);
        uniswapRouter = IUniswapV2Router02(
            new UniswapV2Router02(address(uniswapFactory), address(WETH))
        );

        vm.prank(projectOwner);
        factory = new MemeFactory(
            address(implementation),
            address(uniswapRouter),
            address(WETH),
            address(uniswapFactory)
        );

        vm.deal(memeDeployer, 10 ether);
        vm.deal(buyer, 10 ether);
        vm.deal(anotherBuyer, 10 ether);
    }

    // ... (保持 test_DeployMeme 不变)

    function testMintAndAddLiquidity() public {
        // 1. 部署 Meme 代币
        vm.prank(memeDeployer);
        address tokenAddr = factory.deployMeme(
            TEST_SYMBOL,
            TEST_MAX_SUPPLY,
            TEST_PER_MINT,
            TEST_PRICE
        );
        MemeToken memeToken = MemeToken(tokenAddr);

        // 2. 检查初始 ETH 余额
        uint256 projectOwnerInitialBalance = projectOwner.balance;
        uint256 memeDeployerInitialBalance = memeDeployer.balance;
        uint256 buyerInitialBalance = buyer.balance;

        // 3. 第一次铸币
        vm.prank(buyer);
        factory.mintMeme{value: TEST_PRICE}(tokenAddr);
        // 4. 验证购买者的代币余额和费用分配
        // assertEq(
        //     memeToken.balanceOf(address(factory)),
        //     TEST_PER_MINT,
        //     "Buyer's token balance is incorrect"
        // );
        // assertEq(
        //     memeToken.minted(),
        //     TEST_PER_MINT,
        //     "Minted supply is incorrect"
        // );

        uint256 projectFeeETH = (TEST_PRICE * factory.PROJECT_FEE_BPS()) /
            10000; // 5%
        uint256 deployerFeeETH = TEST_PRICE - projectFeeETH; // 95%

        assertEq(
            projectOwner.balance,
            projectOwnerInitialBalance,
            "Project owner should not receive fee directly"
        );
        assertApproxEqAbs(
            memeDeployer.balance,
            memeDeployerInitialBalance + deployerFeeETH,
            1 wei,
            "Meme deployer should receive 95% fee"
        );
        assertApproxEqAbs(
            buyer.balance,
            buyerInitialBalance - TEST_PRICE,
            1 wei,
            "Buyer's ETH balance should decrease by price"
        );

        // 5. 验证流动性是否添加成功
        address pair = uniswapFactory.getPair(tokenAddr, address(WETH));
        console.log("Uniswap pair address:", pair);
        assertNotEq(pair, address(0), "Uniswap pair should exist");

        // 验证工厂合约的 ETH 和 MemeToken 余额是否为零
        assertEq(
            address(factory).balance,
            0,
            "Factory ETH balance should be 0"
        );
        assertEq(
            memeToken.balanceOf(address(factory)),
            0,
            "Factory token balance should be 0"
        );

        // 验证流动性池中的代币数量
        (uint256 reserve0, uint256 reserve1) = UniswapV2Library.getReserves(
            address(uniswapFactory),
            tokenAddr,
            address(WETH)
        );
        console.log(reserve0);
        console.log(reserve1);
        // console.log("test3");
        // console.log("test4,%s",TEST_PRICE);
        // console.log("test5,%s",TEST_PER_MINT);
        // uint256 u = 10 * 18;
        // console.logUint(u);
        // console.log("test7,%s",(TEST_PRICE / TEST_PER_MINT));
        // uint256 expectedTokenAmount = (projectFeeETH * (10 ** 18)) /
        //     ((TEST_PRICE / TEST_PER_MINT) * (10 ** 18));
        //     console.log("test4");
        // assertEq(reserve0, expectedTokenAmount, "Token reserve is incorrect");
        assertEq(reserve1, projectFeeETH, "ETH reserve is incorrect");
    }

    function testBuyMemeWhenUniswapPriceIsBetter() public {
        // 1. 部署和铸造一次以添加流动性
        vm.prank(memeDeployer);
        address tokenAddr = factory.deployMeme(TEST_SYMBOL, TEST_MAX_SUPPLY, TEST_PER_MINT, TEST_PRICE);
        MemeToken memeToken = MemeToken(tokenAddr);
        vm.prank(buyer);
        factory.mintMeme{value: TEST_PRICE}(tokenAddr);

        // 2. 模拟 ETH 价格上涨，使得 Uniswap 上的 MemeToken 价格变得更便宜
        // 这里只是一个假设，实际情况可以通过交易实现
        // 假设初始价格是 0.01 ETH / 100 Token = 0.0001 ETH/Token
        // 我们可以通过操纵 Uniswap 价格来测试

        // 3. 检查初始 mint 价格
        uint256 initialPrice = (TEST_PRICE * (10 ** memeToken.decimals())) / TEST_PER_MINT;

        // 4. 模拟在 Uniswap 上进行一笔交易，使其价格发生变化
        // 为了方便测试，我们直接假设 Uniswap 的价格比 mint 价格更好
        
        uint256 buyAmount = 0.1 ether;
        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = tokenAddr;

        vm.prank(anotherBuyer);
        uint256[] memory amountsOut = uniswapRouter.getAmountsOut(buyAmount, path);
        uint256 uniswapTokenAmount = amountsOut[1];

        // 5. 调用 buyMeme，并验证购买成功
        vm.prank(anotherBuyer);
        uint256 anotherBuyerInitialBalance = anotherBuyer.balance;

        // 6. 验证 uniswapTokenAmount > initialPrice
        uint256 ethForOneToken = (1 ether * (10 ** memeToken.decimals())) / initialPrice;
        // 如果 Uniswap 上可以用更少的 ETH 换 1 个 token，那么价格更优
        uint256 uniswapEthForOneToken = (1 ether * (10 ** memeToken.decimals())) / uniswapTokenAmount;

        // 如果Uniswap价格比初始价格好，应该可以购买
        assert(uniswapEthForOneToken < ethForOneToken); // 这是一个简单的检查
        vm.prank(anotherBuyer);
        factory.buyMeme{value: buyAmount}(tokenAddr);
        console.log("anotherBuyer balance: ", memeToken.balanceOf(anotherBuyer));
        // 7. 验证余额变化
        assertEq(memeToken.balanceOf(anotherBuyer), uniswapTokenAmount);
        assertApproxEqAbs(anotherBuyer.balance, anotherBuyerInitialBalance - buyAmount, 1 wei, "Buyer's ETH balance should decrease");
    }
}
