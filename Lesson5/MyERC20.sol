// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract MyERC20{
    string public name; 
    string public symbol; 
    uint8 public decimals; 
    uint256 public totalSupply; 

    mapping (address => uint256) balances; 

    mapping (address => mapping (address => uint256)) allowances; 

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name,string memory _symbol,uint8 _decimals,uint _totalSupply) {
        // write your code here
        // set name,symbol,decimals,totalSupply
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply * 10**uint256(_decimals);
        balances[msg.sender] = totalSupply;
    }

    //查询余额
    function balanceOf(address _owner) public view returns (uint256 balance) {
        require(_owner > address(0),"ERC20: balance query for the zero address");
        return balances[_owner];
    }


    function transfer(address _to, uint256 _value) public returns (bool success) {
        // write your code here
        //检查余额
        require(balances[msg.sender] > _value,"ERC20: transfer amount exceeds balance");

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
        require(balances[_from] > _value,"ERC20: transfer amount exceeds balance");
        require(allowances[_from][msg.sender] > _value,"ERC20: transfer amount exceeds allowance");

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
    
}