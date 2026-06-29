// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import "../src/AssessmentContract.sol";

contract AssessmentTest is Test {
  VulnerableContract public vulnerableContract;
  AttackerContract public attackerContract;
  FixedContract public fixedContract;

  address owner = makeAddr("owner");
  address attacker = makeAddr("attacker");
  address user = makeAddr("user");

  function setUp() public {
    vulnerableContract = new VulnerableContract();
    fixedContract = new FixedContract();
    attackerContract = new AttackerContract(address(vulnerableContract));

    vm.deal(owner, 10 ether);
    vm.deal(attacker, 2 ether);
    vm.deal(user, 2 ether);
  }

  // --- VulnerableContract basic tests ---

  function test_initialBalance_isZero() public view {
    assertEq(vulnerableContract.balances(owner), 0);
  }

  function test_deposit_updatesBalance() public {
    vm.prank(owner);
    vulnerableContract.deposit{value: 1 ether}();
    assertEq(vulnerableContract.balances(owner), 1 ether);
  }

  function test_withdraw_reducesBalance() public {
    vm.prank(owner);
    vulnerableContract.deposit{value: 1 ether}();

    vm.prank(owner);
    vulnerableContract.withdraw(1 ether);

    assertEq(vulnerableContract.balances(owner), 0);
  }

  function test_withdraw_revertsIfInsufficientBalance() public {
    vm.prank(owner);
    vm.expectRevert("Insufficient balance");
    vulnerableContract.withdraw(1 ether);
  }

  // --- Reentrancy attack on VulnerableContract ---

  function test_reentrancyAttack_drainsVulnerableContract() public {
    // Owner deposits 5 ETH into the vulnerable contract
    vm.prank(owner);
    vulnerableContract.deposit{value: 5 ether}();

    uint256 contractBalanceBefore = address(vulnerableContract).balance;
    uint256 attackerBalanceBefore = address(attackerContract).balance;

    // Attacker exploits with 1 ETH
    vm.prank(attacker);
    attackerContract.exploit{value: 1 ether}();

    // Attacker drained more than they put in
    assertGt(
      address(attackerContract).balance,
      attackerBalanceBefore + 1 ether,
      "Attacker should have drained extra ETH"
    );
    assertLt(
      address(vulnerableContract).balance,
      contractBalanceBefore,
      "Vulnerable contract should have lost ETH"
    );
  }

  // --- FixedContract tests ---

  function test_fixed_initialBalance_isZero() public view {
    assertEq(fixedContract.balances(user), 0);
  }

  function test_fixed_deposit_updatesBalance() public {
    vm.prank(user);
    fixedContract.deposit{value: 1 ether}();
    assertEq(fixedContract.balances(user), 1 ether);
  }

  function test_fixed_withdraw_reducesBalance() public {
    vm.prank(user);
    fixedContract.deposit{value: 1 ether}();

    vm.prank(user);
    fixedContract.withdraw(1 ether);

    assertEq(fixedContract.balances(user), 0);
  }

  function test_fixed_withdraw_revertsIfInsufficientBalance() public {
    vm.prank(user);
    vm.expectRevert("Insufficient balance");
    fixedContract.withdraw(1 ether);
  }

  function test_fixed_blocksReentrancy() public {
    // Fund the fixed contract with owner deposits
    vm.prank(owner);
    fixedContract.deposit{value: 5 ether}();

    // Deploy an attacker targeting the fixed contract
    AttackerContract fixedAttacker = new AttackerContract(address(fixedContract));
    vm.deal(address(fixedAttacker), 1 ether);

    uint256 contractBalanceBefore = address(fixedContract).balance;

    // The exploit should revert due to nonReentrant guard
    vm.expectRevert();
    fixedAttacker.exploit{value: 1 ether}();

    // Contract balance should be unchanged
    assertEq(address(fixedContract).balance, contractBalanceBefore);
  }
}
