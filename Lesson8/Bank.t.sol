// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "@std//Test.sol";
import {Bank} from "../src/Bank.sol";

contract BankTest is Test { 

    Bank public bank;
    address admin = address(0xbef745E4b89216F50f20A77D057604f007C30E86);
    address user1 = address(0x250E9a79B2aFdC11fd9A0C42a855D84E0Aa2ed19);
    address user2 = address(0x957BbD24fCB9d7E78F57Ec1C7CFf1BD6906a3C51);
    address user3 = address(0xC6fda06C2cfF201e761aF229d771684540444025);
    address user4 = address(0xef1c565803e07D33C0D06b470021Eb84574f6a06);

    function setUp() public {
        vm.prank(admin);
        bank = new Bank();
    }

    //测试存款后余额是否一致
    function test_checkBalance() public {
        vm.deal(user1, 10 ether);
        vm.prank(user1);
        (bool success, ) = address(bank).call{value: 2 ether}("");
        assertTrue(success);
        assertEq(bank.balance(user1), 2 ether);
    }

    // 存款1人
    function testTopDepositorsSingle() public {
        vm.deal(user1, 10 ether);
        vm.prank(user1);
        (bool success, ) = address(bank).call{value: 3 ether}("");

        assertTrue(success);
        assertEq(bank.topDepositors(0), user1);
    }

     // 存款 2 人
    function testTopDepositorsTwoUsers() public {
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);

        vm.prank(user1);
        (bool successUser1, ) = address(bank).call{value: 2 ether}("");
        vm.prank(user2);
        (bool successUser2, ) = address(bank).call{value: 5 ether}("");

        assertTrue(successUser1 && successUser2);
        assertEq(bank.topDepositors(0), user2);
        assertEq(bank.topDepositors(1), user1);
    }

     // 存款 3 人
    function testTopDepositorsThreeUsers() public {
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(user3, 10 ether);

        vm.prank(user1);
        (bool successUser1, ) = address(bank).call{value: 2 ether}("");
        vm.prank(user2);
        (bool successUser2, ) = address(bank).call{value: 5 ether}("");
        vm.prank(user3);
        (bool successUser3, ) = address(bank).call{value: 8 ether}("");

        assertTrue(successUser1 && successUser2 && successUser3);
        assertEq(bank.topDepositors(0), user3);
        assertEq(bank.topDepositors(1), user2);
        assertEq(bank.topDepositors(2), user1);
    }

    // 存款 4 人
    function testTopDepositorsFourUsers() public {
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(user3, 10 ether);
        vm.deal(user4, 10 ether);

        vm.prank(user1);
        (bool successUser1, ) = address(bank).call{value: 2 ether}("");
        vm.prank(user2);
        (bool successUser2, ) = address(bank).call{value: 5 ether}("");
        vm.prank(user3);
        (bool successUser3, ) = address(bank).call{value: 8 ether}("");
        vm.prank(user4);
        (bool successUser4, ) = address(bank).call{value: 3 ether}("");

        assertTrue(successUser1 && successUser2 && successUser3&& successUser4);
        assertEq(bank.topDepositors(0), user3);
        assertEq(bank.topDepositors(1), user2);
        assertEq(bank.topDepositors(2), user4);
    }

      function testTopDepositorMultipleDeposits() public {
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(user3, 10 ether);
        vm.deal(user4, 10 ether);

        vm.prank(user1);
        (bool successUser1, ) = address(bank).call{value: 2 ether}("");
        vm.prank(user2);
        (bool successUser2, ) = address(bank).call{value: 5 ether}("");
        vm.prank(user3);
        (bool successUser3, ) = address(bank).call{value: 8 ether}("");
        vm.prank(user4);
        (bool successUser4, ) = address(bank).call{value: 3 ether}("");
        vm.prank(user1);
        (bool successUser1_2, ) = address(bank).call{value: 2 ether}("");

        assertTrue(successUser1 && successUser2 && successUser3 && successUser4 && successUser1_2);
        assertEq(bank.topDepositors(0), user3);
        assertEq(bank.topDepositors(1), user2);
        assertEq(bank.topDepositors(2), user1);
      }

      function testNotAdminWithdraw() public payable{
        vm.deal(user1, 10 ether);
        vm.prank(user1);
        (bool successUser1, ) = address(bank).call{value: 2 ether}("");
        assertTrue(successUser1);

        vm.prank(user1);
        vm.expectRevert("Only admin can withdraw");
        
        bank.withdraw(1 ether);
      }

      function testAdminWithdraw() public payable{
        vm.deal(user1, 10 ether);
        vm.prank(user1);
        (bool successUser1, ) = address(bank).call{value: 2 ether}("");
        assertTrue(successUser1);

        vm.prank(admin);
     //   vm.expectRevert("Only admin can withdraw");
        console.log("admin balance before withdraw:", admin.balance);
        bank.withdraw(1 ether);
        console.log("admin balance withdraw:", admin.balance);
      }
}