// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/finance/VestingWallet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyVestingWalletWithCliff  is Ownable , VestingWallet {
    // VestingWallet 构造函数需要受益人地址、悬崖期和线性释放时长。
    // 在本例中，我们设定了：
    // - _beneficiary: 合约部署时指定的受益人地址。
    // - _start: 合约部署时的时间戳。
    // - _duration: 总的释放周期，即 12 个月悬崖期 + 24 个月线性释放 = 36 个月。
    // - _cliff: 悬崖期时长，即 12 个月。
    uint64 private _cliff;

    constructor(
        address beneficiaryAddress,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 cliffSeconds // 新增的悬崖期参数
    ) VestingWallet(beneficiaryAddress, startTimestamp, durationSeconds) {
        require(cliffSeconds <= durationSeconds, "cliff cannot be larger than duration");
        _cliff = cliffSeconds;
    }

    // 为了方便，这里添加一个接收 ERC20 代币的函数，部署者可以在部署后调用此函数。
    // 另一种更常见的方式是，在部署时直接将代币从部署者的钱包转入合约。
    function depositTokens(IERC20 _token, uint256 _amount) external {
        // 确保只有合约创建者可以存入代币
        require(msg.sender == owner(), "Only owner can deposit tokens");
        _token.transferFrom(msg.sender, address(this), _amount);
    }

    // 覆写 VestingWallet 的 vestedAmount() 函数 增加 Cliff的处理逻辑
    function vestedAmount(address token, uint64 timestamp) public view virtual override returns (uint256) {
        // 在悬崖期内，可归属的代币为0
        if (timestamp <= start() + _cliff) {
            return 0;
        }

        // 悬崖期过后，使用原始的归属逻辑
        return super.vestedAmount(token, timestamp);
    }
}