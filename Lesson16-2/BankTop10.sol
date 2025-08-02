// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract BankTop10 {
    // 用户结构体
    struct User {
        address addr;
        uint256 balance;
        uint256 prev;
        uint256 next;
    }

    uint256 public constant MAX_TOP = 10;
    // 用户数量
    uint256 public userCount;
    // 用户余额
    mapping(address => uint256) public balances;
    // 用户信息
    mapping(uint256 => User) public users;
    // 地址到用户ID
    mapping(address => uint256) public addressToId;
    // 排行榜头结点
    uint256 public head; // Top 1 user id

    event Deposited(address indexed user, uint256 amount);

    receive() external payable {
        // 收到以太坊后存款
        deposit();
    }

    /**
     * 用户存款
     */
    function deposit() public payable {
        require(msg.value > 0, "No ETH sent");
        if (addressToId[msg.sender] == 0) {
            // 新用户
            userCount++;
            // 记录用户地址到用户ID映射
            addressToId[msg.sender] = userCount;
            // 用户信息
            users[userCount] = User(msg.sender, msg.value, 0, 0);
        } else {
            // 老用户更新余额
            uint256 id = addressToId[msg.sender];
            // 更新余额
            users[id].balance += msg.value;
        }

        balances[msg.sender] += msg.value;
        _updateRanking(msg.sender);
        emit Deposited(msg.sender, msg.value);
    }

    function _updateRanking(address userAddr) internal {
        uint256 id = addressToId[userAddr];
        User storage currentUser = users[id];

        // 先移除节点
        _removeFromRanking(id);

        // 插入排序链表
        if (head == 0) {
            head = id;
            return;
        }

        uint256 cursor = head;
        uint256 prev = 0;

        // 向后遍历找到插入位置
        while (cursor != 0 && users[cursor].balance > currentUser.balance) {
            prev = cursor;
            cursor = users[cursor].next;
        }

        if (prev == 0) {
            // 插入到头部
            currentUser.next = head;
            users[head].prev = id;
            head = id;
        } else {
            // 插入到 prev 后
            currentUser.next = users[prev].next;
            currentUser.prev = prev;

            if (users[prev].next != 0) {
                users[users[prev].next].prev = id;
            }
            users[prev].next = id;
        }

        _truncateRanking();
    }

    function _removeFromRanking(uint256 id) internal {
        if (head == id) {
            head = users[id].next;
        }

        uint256 prev = users[id].prev;
        uint256 next = users[id].next;

        if (prev != 0) {
            users[prev].next = next;
        }
        if (next != 0) {
            users[next].prev = prev;
        }

        users[id].prev = 0;
        users[id].next = 0;
    }

    function _truncateRanking() internal {
        uint256 cursor = head;
        uint256 count = 1;

        while (cursor != 0 && users[cursor].next != 0) {
            if (count == MAX_TOP) {
                uint256 next = users[cursor].next;
                users[cursor].next = 0;
                users[next].prev = 0;
                break;
            }
            cursor = users[cursor].next;
            count++;
        }
    }

    function getTopUsers()
        public
        view
        returns (address[] memory addrs, uint256[] memory amounts)
    {
        addrs = new address[](MAX_TOP);
        amounts = new uint256[](MAX_TOP);
        uint256 cursor = head;
        uint256 i = 0;
        while (cursor != 0 && i < MAX_TOP) {
            addrs[i] = users[cursor].addr;
            amounts[i] = users[cursor].balance;
            cursor = users[cursor].next;
            i++;
        }
    }
}
