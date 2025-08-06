// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/src/v0.8/automation/AutomationCompatible.sol";
contract Bank is Ownable , AutomationCompatible{

    // 用户存款
    mapping(address => uint256) public deposits;
    // 总存款
    uint256 public totalDeposits;
    // 提现阈值
    uint256 public threshold;

    //存款事件
    event Deposit(address indexed user, uint256 amount);
    //取款事件
    event Withdrawal(address indexed user, uint256 amount);
    //存款超阈值后提现事件
    event HalfTransferrred(address indexed to, uint256 amount);

    /**
     *   @dev 构造函数，在合约部署时执行一次
     */
    constructor(uint256 _threshold) Ownable() {
        threshold = _threshold;
    }

    function deposit() public payable {
        //确保存款金额大于0
        require(msg.value > 0, "Deposit amount must be greater than 0");

        //更新存款余额
        deposits[msg.sender] += msg.value;
        //更新总存款
        totalDeposits += msg.value;

        //触发存款事件
        emit Deposit(msg.sender, msg.value);
    }

    /**
     *  @dev 提现函数
     *  用户提款函数
     */
    function withrawal(uint256 amount) public {
        require(deposits[msg.sender] >= amount, "Insufficient balance");
        deposits[msg.sender] -= amount;
        totalDeposits -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed.");

        emit Withdrawal(msg.sender, amount);
    }

    /**
    按条件执行
    */
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData){
        upkeepNeeded = address(this).balance >= threshold;
    }
    /**
    * 按时间执行
     * 仅限自动化任务调用函数
     * 
     */
    function performUpkeep(bytes calldata performData) external {
        //检查总存款是否超过阈值，以防止误操作
        require(totalDeposits >= threshold, "Total deposits below threshold");

        // 计速需要转移的金额
        uint256 amountToTransfer = address(this).balance;

        // 更新总存款
        totalDeposits -= amountToTransfer;

        // 将一半的资金转移给所有者
        (bool success, ) = payable(owner()).call{value: amountToTransfer}("");
        require(success, "Failed to send Ether");

        emit HalfTransferrred(owner(), amountToTransfer);
    }

    function emergencyWithdrawAll() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        (bool success, ) = payable(owner()).call{value: contractBalance}("");
        require(success, "Failed to send Ether");
    }
}
