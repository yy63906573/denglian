// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MyTokenPermit.sol";
import "./IPermit2.sol";
contract TokenBankPermit2 {
    MyTokenPermit public immutable myTokenPermit;
    // 用来记录每个地址的存款余额
    mapping(address => uint256) public deposits;
    // 事件，表示存款和取款
    event Deposited(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);

    address public immutable permit2;
    constructor(address _tokenAddress, address _permit2) {
        // 将传入的合约地址转换成 BaseERC20 实例
        myTokenPermit = MyTokenPermit(_tokenAddress);
        permit2 = _permit2;
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

        myTokenPermit.permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );
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

    /**
     * @notice 使用 Permit2 授权转账方式进行存款
     * @param permit 用户链下签名授权的参数，包括 token 地址、授权金额、nonce、过期时间
     * @param transferDetails 实际执行转账的目标地址和金额（可小于 permit.amount）
     * @param owner 代币的拥有者，即签名的发起人（一般是 msg.sender）
     * @param signature 用户针对 permit 参数的 EIP-712 签名
     */
    function depositWithPermit2(
        IPermit2.PermitTransferFrom calldata permit,
        IPermit2.SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external {
        //调用 Permit2 合约的 permitTransferFrom 方法
        //Permit2 合约会校验签名是否有效、nonce 是否已使用、deadline 是否过期等
        //校验通过后，将从 owner 的地址中转出 transferDetails.requestedAmount 个 token
        //并转到 transferDetails.to（一般是本合约地址）

        IPermit2(permit2).permitTransferFrom(
            permit, // 用户授权的 token、amount、nonce、deadline
            transferDetails, // 实际转账目标和金额
            owner, // 拥有者（签名人）
            signature // 签名消息
        );
        // 更新存款记录
        deposits[msg.sender] += permit.amount;
        emit Deposited(msg.sender, permit.amount);
    }
}
