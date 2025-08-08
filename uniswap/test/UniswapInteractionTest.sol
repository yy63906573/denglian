// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "@v2-core/UniswapV2Factory.sol";
import "src/MyToken.sol"; 

contract UniswapInteractionTest is Test {
    UniswapV2Factory public factory;

    function setUp() public {
        // 在这里部署 Uniswap Factory 和其他代币
        factory = new UniswapV2Factory(address(this));
    }

    function testCreatePair() public {
        uint256 privateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        //设置private key
        vm.startBroadcast(privateKey);
        MyToken token1 = new MyToken("kekexili","keke",100000000 ether);
        MyToken token2 = new MyToken("yangyang","yy",100000000 ether);
        vm.stopBroadcast();

        // 创建两个模拟代币
        address tokenA = address(token1);
        address tokenB = address(token2);

        // 调用工厂合约的 createPair 方法
        address pairAddress = factory.createPair(tokenA, tokenB);

        // 验证配对合约地址不为零
        assert(pairAddress != address(0));

        // 验证工厂合约能够正确返回配对地址
        assertEq(factory.getPair(tokenA, tokenB), pairAddress);
    }
}