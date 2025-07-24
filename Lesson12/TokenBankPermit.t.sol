// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TokenBankPermit} from "../src/TokenBankPermit.sol";
import {MyTokenPermit} from "../src/MyTokenPermit.sol";
import "forge-std/Test.sol";

contract TokenBankPermitTest is Test {
    TokenBankPermit public tokenBankPermit;
    MyTokenPermit public myTokenPermit;
    address public admin = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    uint256 public adminPrivatekey =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    address public user1 = address(0x250E9a79B2aFdC11fd9A0C42a855D84E0Aa2ed19);
    //address user2 = address();

    function setUp() public {

        vm.prank(admin);
        myTokenPermit = new MyTokenPermit();
        vm.prank(admin);
        tokenBankPermit = new TokenBankPermit(address(myTokenPermit));
    }

    function test_deposit() public {
        uint256 amount = 100 ether;
        uint256 deadline = block.timestamp + 3600;

        vm.prank(admin);
        uint256 nonce = myTokenPermit.nonces(admin);

        bytes32 digest = getPermitDigest(
            admin,
            address(tokenBankPermit),
            amount,
            nonce,
            deadline
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(adminPrivatekey, digest);
        // 授权 TokenBankPermit 合约使用 MyTokenPermit 的代币
        vm.prank(admin);
        tokenBankPermit.permitDeposit(amount, deadline, v, r, s);
        console.log(
            "admin deposit amount: %s",
            tokenBankPermit.balance(admin)
        );
    }

    function getPermitDigest(
        address owner,
        address spender,
        uint256 value,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256(
                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                ),
                owner,
                spender,
                value,
                nonce,
                deadline
            )
        );

        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("yangyang")),
                keccak256(bytes("1")),
                block.chainid,
                address(myTokenPermit)
            )
        );

        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );
    }
}
