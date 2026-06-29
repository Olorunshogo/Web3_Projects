// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract CounterV2 {
  uint256 public number;
  address public owner;

  constructor() {
    owner = msg.sender;
  }


  function setNumber(uint256 newNumber) public {
    require(msg.sender == owner, "Not owner");
    number = newNumber;
  }

  function increment() public {
    require(msg.sender == owner, "Not owner");
    number++;
  }
}
