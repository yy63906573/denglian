// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/BankTop10.sol";

contract Deploy is Script {
    BankTop10 public bank;

    function run() external { 
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);
        bank = BankTop10(payable(address(0x04774755ce932d9C167E59cBb23Bf69a706FFFB9)));
        (address[] memory addrs, uint256[] memory amounts) = bank.getTopUsers();
        for (uint i = 0; i < addrs.length; i++) {
            console.log("address: %s, amount: %s", addrs[i], amounts[i]);
        }
        console.log("BankTop10 contract call successfully!");
        vm.stopBroadcast();
    }

}