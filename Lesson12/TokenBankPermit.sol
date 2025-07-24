// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MyTokenPermit.sol";
contract TokenBankPermit {
    MyTokenPermit public myTokenPermit;
    // 用来记录每个地址的存款余额
    mapping(address => uint256) public deposits;
    // 事件，表示存款和取款
    event Deposited(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);
    constructor(address _tokenAddress) {
        // 将传入的合约地址转换成 BaseERC20 实例
        myTokenPermit = MyTokenPermit(_tokenAddress);
    }

    // 存款方法
    function deposit(uint256 amount) external {
        require(amount > 0, "TokenBank: deposit amount must be greater than 0");
        myTokenPermit.transferFrom(msg.sender, address(this), amount);
        // 更新存款记录
        deposits[msg.sender] += amount;

        emit Deposited(msg.sender, amount);
    }

    function permitDeposit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(amount > 0, "TokenBank: deposit amount must be than 0");

        myTokenPermit.permit(msg.sender,address(this), amount,deadline,v,r,s);
        myTokenPermit.transferFrom(msg.sender, address(this), amount);
        // 更新存款记录
        deposits[msg.sender] += amount;
        emit Deposited(msg.sender, amount);
    }
    // 提款方法
    function withdraw(uint256 amount) external {
        require(amount > 0, "TokenBank: withdraw amount must be than 0");
        require(
            deposits[msg.sender] >= amount,
            "TokenBank: insufficient balance"
        );

        myTokenPermit.transfer(msg.sender, amount);
        // 更新存款余额
        deposits[msg.sender] -= amount;
        emit Withdrawn(msg.sender, amount);
    }

    // 查询用户存入的代币余额
    function balance(address account) external view returns (uint256) {
        return deposits[account];
    }
}
