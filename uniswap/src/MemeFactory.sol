// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/proxy/Clones.sol";
import "./MemeToken.sol";

/**
 * @title MemeFactory (Meme工厂)
 * @dev 一个使用最小化代理模式（EIP-1167）来部署新MemeToken实例的工厂合约。
 * @dev 这种方式极大地为Meme创建者降低了Gas成本。
 */
contract MemeFactory {
    // --- 状态变量 ---
    address public immutable implementation; // MemeToken逻辑合约的地址
    address public immutable projectOwner; // 项目方地址，用于接收费用
    uint256 public constant PROJECT_FEE_BPS = 100; // 项目费用的基点（BPS），100 BPS = 1%

    // --- 事件 ---
    event MemeDeployed(
        address indexed tokenAddress,
        address indexed deployer,
        string symbol,
        uint256 totalSupply
    );

    // --- 自定义错误 ---
    error InvalidPayment();

    // --- 构造函数 ---
    constructor(address _implementation) {
        implementation = _implementation;
        projectOwner = msg.sender;
    }

    // --- 外部函数 ---

    /**
     * @dev 部署一个新的MemeToken代理合约。
     * @param symbol 新代币的符号（例如 "PEPE"）。
     * @param totalSupply 代币的最大总供应量。
     * @param perMint 每次调用 'mintMeme' 时铸造的代币数量。
     * @param price 铸造一批 'perMint' 数量代币的成本（单位：wei）。
     * @return tokenAddr 新创建的Meme代币合约地址。
     */
    function deployMeme(
        string memory symbol,
        uint256 totalSupply,
        uint256 perMint,
        uint256 price
    ) external returns (address tokenAddr) {
        require(totalSupply > 0, "totalSupply ,must be greater than 0");
        require(perMint > 0, "perMint must be greater than 0");

        // 使用OpenZeppelin的Clones库来创建最小化代理合约
        tokenAddr = Clones.clone(implementation);

        // 使用其特定参数初始化新的克隆合约。
        // 工厂合约（`address(this)`）成为新MemeToken的所有者。
        MemeToken(tokenAddr).initialize(
            symbol,
            msg.sender,
            totalSupply,
            perMint,
            price
        );

        emit MemeDeployed(tokenAddr, msg.sender, symbol, totalSupply);
    }

    /**
     * @dev 为用户铸造一批代币并分配费用。
     * @notice 当用户铸造代币时，必须支付ETH作为费用。其中1%将分配给项目方，99%将分配给Meme发行者。
     * @dev 确保用户支付的金额与MemeToken的 'price' 属性一致。
     * @param tokenAddr 需要铸造的Meme代币的合约地址。
     */
    function mintMeme(address tokenAddr) external payable {
        MemeToken token = MemeToken(tokenAddr);
        uint256 price = token.price();
        address deployer = token.creator();

        // 1. 验证支付金额

        require(msg.value == price, "Incorrect payment amount");

        // 2. 分配费用
        uint256 projectFee = (msg.value * PROJECT_FEE_BPS) / 10000; // 1%
        uint256 deployerFee = msg.value - projectFee; // 99%

        //1%的ETH发送给项目方
        (bool projectSuccess, ) = projectOwner.call{value: projectFee}("");
        require(projectSuccess, "project fee transfer failed");
        //99%的ETH发送给部署者
        (bool deployerSuccess, ) = deployer.call{value: deployerFee}("");
        require(deployerSuccess, "deployer fee transfer failed");

        // 3. 为用户（msg.sender）铸造代币
        token.mint(msg.sender);
    }
}
