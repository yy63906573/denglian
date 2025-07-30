// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface ITokenRecipient {
    function tokensReceived(address from, uint256 amount, bytes calldata data) external returns(bool);
}

contract MyTokenPermit is ERC20,ERC20Permit {
    constructor() ERC20("yangyang", "yy") ERC20Permit("yangyang") {
        _mint(msg.sender, 1000000 ether);
    }
}
