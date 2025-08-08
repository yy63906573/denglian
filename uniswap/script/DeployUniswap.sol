// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "@v2-core/UniswapV2Factory.sol";
import "@v2-core/UniswapV2Pair.sol";
//import "@v2-periphery/test/WETH9.sol";
//import "@v2-periphery/UniswapV2Router02.sol";
contract DeployUniswap is Script {
    function run() external {
        vm.startBroadcast();
        
        // 1. 部署 WETH 合约
       // WETH9 weth = new WETH9();
        vm.startPrank(address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266)); // 使用一个常用的测试账户地址
        // 2. 部署 Uniswap V2 工厂合约
//         好的，我们来详细解释一下这两行代码的作用和它们的参数。
// 这两行代码的作用是部署 Uniswap V2 的核心组件：工厂合约和路由合约。
// 1. 部署 Uniswap V2 工厂合约

// 参数的作用：feeToSetter
// feeToSetter 是一个特殊的地址，它拥有修改 feeTo 地址的权限。feeTo 地址用于接收 Uniswap V2 协议产生的交易费用。
// 在你的 Foundry 脚本中，address(this) 指向的是当前正在执行部署脚本的合约（DeployUniswap）。这是一种常见的做法，让部署者自己来控制这个权限。
// 总结：这行代码部署了 Uniswap V2 的核心。工厂合约是所有流动性池（Pair）的创建者和管理者。没有它，你无法创建任何交易对。
        UniswapV2Factory factory = new UniswapV2Factory(msg.sender);
        
        // 3. 部署 Uniswap V2 路由合约，并将 WETH 地址传入
//         参数的作用：_factory 和 _WETH
// 路由合约（Router）是与用户交互的接口。它不直接创建流动性池，而是调用工厂合约来完成这个任务。路由合约需要知道工厂合约的地址，才能正确地与它进行通信。

// 同样，路由合约提供了将原生 ETH 转换为 WETH 的功能，以及进行涉及 ETH 的代币交易。因此，它需要知道 WETH 合约的地址。

// 总结：这行代码部署了 Uniswap V2 的外围。路由合约是用户用来添加流动性、进行代币交换等操作的入口。它通过工厂合约和 WETH 合约的地址，来执行这些复杂的交易逻辑。
       // UniswapV2Router02 router = new UniswapV2Router02(address(factory), address(weth));
        
        vm.stopBroadcast();
    }
}