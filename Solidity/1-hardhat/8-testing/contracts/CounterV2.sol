// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract CounterV2 {
  uint public x;
  address public owner;

  event Increment(uint by);
  event Decrement(uint by);

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Not the owner");
    _;
  }

  function inc() public onlyOwner {
    x++;
    emit Increment(1);
  }

  function incBy(uint by) public onlyOwner {
    require(by > 0, "incBy: increment should be positive");
    x += by;
    emit Increment(by);
  }

  // Decrement by 1
  function dec() public onlyOwner {
    require(x > 0, "Counter cannot go below 0.");
    x -= 1;
    emit Decrement(1);
  }

  // Decrement by specific amount
  function decBy(uint amount) public onlyOwner {
    require(amount > 0, "Amount must be greater than 0.");
    require(x >= amount, "Counter cannot go below 0.");
    x -= amount;
    emit Decrement(amount);
  }
}
