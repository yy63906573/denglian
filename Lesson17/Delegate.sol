// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title EIP-7702 Delegate
/// @notice A simple delegate contract that can execute a batch of calls.
contract Delegate {
    struct Call {
        address target;
        uint256 value;
        bytes data;
    }

    /// @notice Executes a batch of calls.
    /// @param calls An array of Call structs.
    function execute(Call[] calldata calls) external payable {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, ) = calls[i].target.call{value: calls[i].value}(calls[i].data);
            require(success, "Execution failed");
        }
    }
}