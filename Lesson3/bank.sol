// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank {
    //uint256 public balance = 0;  // 余额
    uint public withdrawalsCount = 0;// 提现次数
    address[3] public topDepositors;
    //余额
    mapping (address => uint) public balance;

    receive() external payable{

        balance[msg.sender] += msg.value;
        updateTopDepositors(msg.sender);
    }
   
    // 管理员地址
    address public admin;
    

    // 构造函数，设置管理员
    constructor() {
        admin = msg.sender;
    }
    /**
        记录前三名存款地址
    */
    function updateTopDepositors(address depositor) private  {
        // 获取当前存款金额
        uint depositAmount = balance[depositor];
        //判断该地址是否存在
        bool isExits = false;
        uint index = 0;
        for(uint i=0; i<3; i++){
            if(topDepositors[i] == depositor) { 
                isExits = true;
                index = i;
                break;
            }
        }
        //如果不存在
        if(!isExits){
             // 找到 depositor 应插入的位置
            for (uint i = 0; i < 3; i++) {
                if (depositAmount > balance[topDepositors[i]]) {
                    // 将 depositor 插入到位置 i，后续地址后移
                    shiftAndInsert(i, depositor);
                    break;
                }
            }
            
        }else{
             //存在，重新排序
            sortTopDepositors();
        }
       

    }


    function shiftAndInsert(uint position,address depositor) internal {
        for (uint i = 2; i > position; i--) {
            topDepositors[i] = topDepositors[i - 1];
        }
        topDepositors[position] = depositor;
    }

    function sortTopDepositors() internal {
        address[3] memory sorted = topDepositors;
        
        if (balance[sorted[0]] < balance[sorted[1]]) {
            (sorted[0], sorted[1]) = (sorted[1], sorted[0]);
        }
        if (balance[sorted[1]] < balance[sorted[2]]) {
            (sorted[1], sorted[2]) = (sorted[2], sorted[1]);
        }
        if (balance[sorted[0]] < balance[sorted[1]]) {
            (sorted[0], sorted[1]) = (sorted[1], sorted[0]);
        }

        topDepositors = sorted;
    }

    // 提取资金函数，仅管理员可以调用
    function withdraw(uint amount) public payable{
        require(msg.sender == admin, "Only admin can withdraw");
        require(amount <= address(this).balance, "Insufficient contract balance");
        withdrawalsCount++;
        payable(admin).transfer(amount);
     
    }
    
}