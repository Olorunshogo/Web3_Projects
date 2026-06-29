// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  uint private _totalSupply;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint)) private _allowances;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals,
    uint initialSupply
  ) {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;

    // Mint tokens to contract creator
    _mint(msg.sender, initialSupply);
  }

  // Total Supply
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  // Total balance
  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  // Allowances
  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowances[owner][spender];
  }

  // Transfer
  function _transfer(address from, address to, uint amount) internal {
    // Verify that it's not address zero calling
    require(to != address(0), "Transfer to zero address");

    uint256 senderBalance = _balances[from];
    require(senderBalance >= amount, "Insufficient funds");

    unchecked{
      _balances[from] = senderBalance - amount;
      _balances[to] += amount;
    }

    emit Transfer(from, to, amount);
  }

  //   Mint
  function _mint(address account, uint amount) internal {

    // Verify that it's not address zero calling
    require(account != address(0), "Cannot mint to zero address");

    _totalSupply += amount;
    _balances[account] += amount;

    emit Transfer(address(0), account, amount);
  }

  // Burn
  function _burn(uint amount) internal {
    require(_balances[msg.sender] >= amount, "Insufficient funds");
    require(msg.sender != address(0), "Cannot call from address 0");

    _totalSupply -= amount;
    _balances[msg.sender] -= amount;
    _balances[address(0)] += amount;

    emit Transfer(msg.sender, address(0), amount);
  }

  // Approve
  function approve(address spender, uint amount) external returns (bool) {
    // State changing functions should always be returning a boolean. That return is used to check if the operation is successful or not.abi
    // Any external function that calls an internal will now be the one that returns it
    require(spender != address(0), "Cannot approve to zero address");

    _allowances[msg.sender][spender] = amount;

    emit Approval(msg.sender, spender, amount);
    return true;
  }

  // transferFrom: Helps others to spend from your own account
  function transferFrom(address from, address to, uint amount) external returns (bool) {
    uint256 currentAllowance = _allowances[from][msg.sender];
    require(currentAllowance >= amount, "Insufficient allowance");

    _allowances[from][msg.sender] = currentAllowance - amount;

    emit Approval(from, msg.sender, _allowances[from][msg.sender]);
    _transfer(from, to, amount);
    return true;
  }

  // transfer() public function
  function transfer(address to, uint amount) external returns (bool) {
    _transfer(msg.sender, to, amount);
    return true;
  }

  // mint() public function
  function mint(uint256 amount) external returns (bool) {
    _mint(msg.sender, amount);
    return true;
  }


}
