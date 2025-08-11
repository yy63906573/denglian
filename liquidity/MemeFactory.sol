// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/proxy/Clones.sol";
import "@v2-core/interfaces/IUniswapV2Router02.sol";
import "@v2-core/interfaces/IUniswapV2Factory.sol";
import "./MemeToken.sol";

contract MemeFactory {
    // --- 状态变量 ---
    address public immutable implementation;
    address public immutable projectOwner;
    uint256 public constant PROJECT_FEE_BPS = 500; // 修改为 5%
    IUniswapV2Router02 public immutable uniswapRouter;
    IUniswapV2Factory public immutable uniswapFactory;
    address public immutable WETH;

    // --- 事件 ---
    event MemeDeployed(
        address indexed tokenAddress,
        address indexed deployer,
        string symbol,
        uint256 totalSupply
    );
    event LiquidityAdded(address indexed token, uint256 amountETH, uint256 amountToken, address lpToken);

    // --- 自定义错误 ---
    error InvalidPayment();
    error LiquidityAddFailed();
    error NotEnoughAllowance();

    // --- 构造函数 ---
    constructor(address _implementation, address _router, address _weth, address _factory) {
        implementation = _implementation;
        projectOwner = msg.sender;
        uniswapRouter = IUniswapV2Router02(_router);
        uniswapFactory = IUniswapV2Factory(_factory);
        WETH = _weth;
    }

    // --- 外部函数 ---

    function deployMeme(
        string memory symbol,
        uint256 totalSupply,
        uint256 perMint,
        uint256 price
    ) external returns (address tokenAddr) {
        require(totalSupply > 0, "totalSupply must be greater than 0");
        require(perMint > 0, "perMint must be greater than 0");
        require(price > 0, "price must be greater than 0");

        tokenAddr = Clones.clone(implementation);

        MemeToken(tokenAddr).initialize(
            symbol,
            msg.sender,
            totalSupply,
            perMint,
            price
        );

        emit MemeDeployed(tokenAddr, msg.sender, symbol, totalSupply);
    }
    
    function mintMeme(address tokenAddr) external payable {
        MemeToken token = MemeToken(tokenAddr);
        uint256 price = token.price();
        address deployer = token.creator();
        
        // 1. 验证支付金额
        if (msg.value != price) {
            revert InvalidPayment();
        }

        // 2. 分配费用
        uint256 projectFeeETH = (msg.value * PROJECT_FEE_BPS) / 10000; // 5%
        uint256 deployerFeeETH = msg.value - projectFeeETH; // 95%

        // 3. 为用户铸造代币
        uint256 perMint = token.perMint();
        token.mint(address(this));
        
        // 4. 将 5% 的ETH和相应Token添加到流动性池
        // 如果是第一次添加流动性，需要为路由合约授权
        // 每次铸造token的每一枚的token单价
        uint256 priceRatio = (price * (10 ** 18)) / perMint;
        // 项目方的EHT数量 = 实际提供的 5% ETH
        uint256 ethPrice = projectFeeETH * (10 ** token.decimals());
        // 计算需要提供的Token数量 = 项目方提供的 5% ETH / 每枚Token的 ETH价格
        uint256 tokenToProvide = ethPrice / priceRatio;
        
        // 授权工厂合约使用 MemeToken
        token.approve(address(uniswapRouter), tokenToProvide);
        // 添加流动性到 Uniswap
        //发送5%的ETH给路由合约，给tokenAddr 添加tokenToProvide 的流动性
        (uint256 amountToken, uint256 amountETH, uint256 liquidity) = uniswapRouter.addLiquidityETH{value: projectFeeETH}(
            tokenAddr,
            tokenToProvide,
            0, // min token amount
            0, // min ETH amount
            address(this),
            block.timestamp
        );
        
        address pair = uniswapFactory.getPair(tokenAddr, WETH);
        emit LiquidityAdded(tokenAddr, amountETH, amountToken, pair);

        // 5. 剩余ETH转给部署者
        (bool deployerSuccess, ) = deployer.call{value: deployerFeeETH}("");
        require(deployerSuccess, "deployer fee transfer failed");
        // 6. 剩余Token转给部署者
        uint256 tokenBalance = token.balanceOf(address(this));
        token.transfer(deployer, tokenBalance);
        
    }

    function buyMeme(address tokenAddr) external payable {
        MemeToken token = MemeToken(tokenAddr);
        
        // 确保交易对存在
        address pair = uniswapFactory.getPair(tokenAddr, WETH);
        require(pair != address(0), "Uniswap pair does not exist");
        
        // 确保支付金额 > 0
        require(msg.value > 0, "Must send ETH");

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = tokenAddr;

        // 1. 获取 Uniswap 上的价格
        uint256[] memory amounts = uniswapRouter.getAmountsOut(msg.value, path);
        uint256 uniswapTokenAmount = amounts[1];
        
        // 2. 获取初始 mint 价格
        uint256 initialPrice = token.price() / token.perMint();
        
        // 3. 比较价格，确保 Uniswap 价格优于 mint 价格
        require(uniswapTokenAmount > initialPrice, "Uniswap price is not better than initial price");
        
        // 4. 调用 Uniswap Router 进行购买
        uniswapRouter.swapExactETHForTokens{value: msg.value}(
            uniswapTokenAmount, // min token amount to receive
            path,
            msg.sender,
            block.timestamp
        );
    }
}