// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITokenRecipient {
    function tokensReceived(address from, uint256 amount, bytes calldata data) external returns(bool);
}

contract MyERC20V3{
    string public name; 
    string public symbol; 
    uint8 public decimals; 

    uint256 public totalSupply; 

    mapping (address => uint256) public balances; 

    mapping (address => mapping (address => uint256)) public allowances; 

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        // write your code here
        // set name,symbol,decimals,totalSupply
        name = "SSS";
        symbol = "S7";
        decimals = 18;
        totalSupply = 10000 * 10**uint256(decimals);
        balances[msg.sender] = totalSupply;
    }

    //查询余额
    function balanceOf(address _owner) public view returns (uint256 balance) {
        // 这是一个良好实践的检查，可以保留，确保查询地址有效。
        // 在0.8.0+版本，查询零地址的balances会返回0，不会直接revert，
        // 但这个require明确了不允许查询零地址的业务逻辑。
        require(_owner > address(0),"BALANCE_QUERY_FOR_THE_ZERO_ADDRESS");
        return balances[_owner];
    }


    function transfer(address _to, uint256 _value) public returns (bool success) {
        // write your code here
        //检查余额
        require(balances[msg.sender] > _value,"TRANSFER_AMOUNT_EXCEEDS_BALANCE");

        //扣除余额
        balances[msg.sender] -= _value;
        //增加余额
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);  
        return true;
    }

    //转移
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // write your code here
        require(balances[_from] >= _value,"TRANSFER_AMOUNT_EXCEEDS_BALANCE");
        require(allowances[_from][msg.sender] >= _value,"TOKEN_TRANSFER_AMOUNT_EXCEEDS_ALLOWANCE");

        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -=_value;

        emit Transfer(_from, _to, _value); 
        return true; 
    }

    //授权
    function approve(address _spender, uint256 _value) public returns (bool success) {
        // write your code here
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true; 
    }

    //查询授权额度
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {   
        // write your code here
        return allowances[_owner][_spender];
    }

    //给某个地址转钱，如果是合约地址回调合约的接收函数
    function transferWithCallback(address _to,uint amount,bytes calldata data) external {
        require(balances[msg.sender] >= amount, "TRANSFER_AMOUNT_EXCEEDS_BALANCE");
        balances[msg.sender] -= amount;
        balances[_to] += amount;

        if(isContract(_to)){
            //如果是合约地址 回调TokenBankV2 的tokensReceived函数
            ITokenRecipient(_to).tokensReceived(msg.sender,amount,data);
            emit Transfer(msg.sender, _to, amount);
            // try ITokenRecipient(_to).tokensReceived(msg.sender,amount,data){
            //     emit Transfer(msg.sender, _to, amount); 
            // }catch{
            //     revert("TOKENSRECEIVED_HOOK_FAILED");
            // }
            
        }
    }
    //判断是否是合约地址
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }
}