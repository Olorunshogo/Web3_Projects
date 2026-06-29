// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/TimelockVaultV2.sol";
import "../src/ClassWorkToken.sol";
import "forge-std/console.sol";

contract TimelockV2Test is Test {
  TimelockVaultV2 internal vault;
  ClassWorkToken internal token;

  address internal user = makeAddr("user");
  address internal otherUser = makeAddr("otherUser");

  uint256 constant ONE_ETHER = 1 ether;
  uint256 constant ONE_DAY = 1 days;
  uint256 constant ONE_WEEK = 7 days;

  // === Setup
  function setUp() public {
    token = new ClassWorkToken(address(this), address(this));
    vault = new TimelockVaultV2(address(token));

    token.transferOwnership(address(vault));

    vm.deal(user, 100 ether);
    vm.deal(otherUser, 100 ether);
  }

  // === Deployment
  function testDeploymentSetsTokenCorrectly() public view {
    console.log("Test 1");
    console.log(" ");

    assertEq(address(vault.token()), address(token));
  }

  function testVaultStartsEmpty() public view {
    console.log("Test 2");
    console.log(" ");

    assertEq(vault.getVaultCount(user), 0);
    assertEq(vault.getTotalBalance(user), 0);
    assertEq(vault.getUnlockedBalance(user), 0);
  }

  // === Deposit Tests
  function testDepositRevertsIfZeroETH() public {
    console.log("Test 3");
    console.log(" ");

    vm.prank(user);
    vm.expectRevert("Deposit must be greater than zero");
    vault.deposit{value: 0}(block.timestamp + ONE_WEEK);
  }

  function testDepositRevertsIfUnlockTimeInPast() public {
    console.log("Test 4");
    console.log(" ");

    vm.prank(user);
    vm.expectRevert("Unlock time must be in the future");
    vault.deposit{value: ONE_ETHER}(block.timestamp - 1);
  }

  function testDepositMintsCorrectAmountOfTokens() public {
    console.log("Test 5");
    console.log(" ");

    vm.prank(user);

    uint unlock = block.timestamp + ONE_WEEK;
    vault.deposit{value: ONE_ETHER}(unlock);

    uint expectedTokens = ONE_ETHER * 10;
    assertEq(token.balanceOf(user), expectedTokens);
  }

  function testDepositCreatesVaultCorrectly() public {
    console.log("Test 6");
    console.log(" ");

    vm.prank(user);

    uint unlock = block.timestamp + ONE_WEEK;
    uint id = vault.deposit{value: ONE_ETHER}(unlock);

    (uint balance, uint tokenBalance, uint unlockTime, bool active, bool isUnlocked) = vault
      .getVault(user, id);

    assertEq(balance, ONE_ETHER);
    assertEq(tokenBalance, ONE_ETHER * 10);
    assertEq(unlockTime, unlock);
    assertTrue(active);
    assertFalse(isUnlocked);
  }

  function testDepositEmitsEvent() public {
    console.log("Test 7");
    console.log(" ");

    uint unlock = block.timestamp + ONE_WEEK;

    vm.prank(user);
    vm.expectEmit(true, true, false, true);
    emit TimelockVaultV2.Deposited(user, 0, ONE_ETHER, unlock);

    vault.deposit{value: ONE_ETHER}(unlock);
  }

  // === Withdraw Tests
  function testWithdrawRevertsInvalidVaultId() public {
    console.log("Test 8");
    console.log(" ");

    vm.prank(user);
    vm.expectRevert("Invalid vault ID");
    vault.withdraw(0);
  }

  function testWithdrawRevertsIfLocked() public {
    console.log("Test 9");
    console.log(" ");

    vm.startPrank(user);

    uint unlock = block.timestamp + ONE_WEEK;
    vault.deposit{value: ONE_ETHER}(unlock);

    vm.expectRevert("Funds are still locked");
    vault.withdraw(0);

    vm.stopPrank();
  }

  function testWithdrawRevertsWithoutApproval() public {
    console.log("Test 10");
    console.log(" ");

    vm.startPrank(user);

    uint unlock = block.timestamp + ONE_WEEK;
    vault.deposit{value: ONE_ETHER}(unlock);

    vm.warp(unlock + 1);

    vm.expectRevert();
    vault.withdraw(0);

    vm.stopPrank();
  }

  function testWithdrawBurnsTokensAndReturnsETH() public {
    console.log("Test 11");
    console.log(" ");

    vm.startPrank(user);

    uint unlock = block.timestamp + ONE_WEEK;
    vault.deposit{value: ONE_ETHER}(unlock);

    uint tokens = token.balanceOf(user);
    token.approve(address(vault), tokens);

    vm.warp(unlock + 1);

    uint before = user.balance;

    vm.expectEmit(true, true, false, true);
    emit TimelockVaultV2.Withdrawn(user, 0, ONE_ETHER);

    vault.withdraw(0);

    assertEq(user.balance, before + ONE_ETHER);
    assertEq(token.balanceOf(user), 0);

    vm.stopPrank();
  }

  // === Withdraw all tests
  function testWithdrawAllRevertsIfNothingUnlocked() public {
    console.log("Test 12");
    console.log(" ");

    vm.prank(user);
    vault.deposit{value: ONE_ETHER}(block.timestamp + ONE_WEEK);

    vm.expectRevert("No unlocked funds available");
    vault.withdrawAll();
  }

  function testWithdrawAllOnlyWithdrawsUnlockedVaults() public {
    console.log("Test 13");
    console.log(" ");

    vm.startPrank(user);

    uint unlock = block.timestamp + ONE_WEEK;

    vault.deposit{value: 2 ether}(unlock);
    vault.deposit{value: 3 ether}(unlock + ONE_WEEK);

    uint tokens = token.balanceOf(user);
    token.approve(address(vault), tokens);

    vm.warp(unlock + 1);

    uint before = user.balance;

    uint withdrawn = vault.withdrawAll();

    assertEq(withdrawn, 2 ether);
    assertEq(user.balance, before + 2 ether);
    assertEq(vault.getTotalBalance(user), 3 ether);

    vm.stopPrank();
  }

  function testCannotWithdrawTwice() public {
    console.log("Test 14");
    console.log(" ");

    vm.startPrank(user);

    uint unlock = block.timestamp + ONE_WEEK;
    vault.deposit{value: ONE_ETHER}(unlock);

    uint tokens = token.balanceOf(user);
    token.approve(address(vault), tokens);

    vm.warp(unlock + 1);

    vault.withdraw(0);

    vm.expectRevert("Vault is not active");
    vault.withdraw(0);

    vm.stopPrank();
  }

  // === View Functions Tests
  function testGetActiveVaults() public {
    console.log("Test 15");
    console.log(" ");

    vm.startPrank(user);

    uint unlock = block.timestamp + ONE_WEEK;

    vault.deposit{value: 1 ether}(unlock);
    vault.deposit{value: 2 ether}(unlock + ONE_DAY);

    vm.stopPrank();

    (uint[] memory ids, , , ) = vault.getActiveVaults(user);

    assertEq(ids.length, 2);
    assertEq(ids[0], 0);
    assertEq(ids[1], 1);
  }

  function testOtherUserHasIndependentVaults() public {
    console.log("Test 16");
    console.log(" ");

    vm.prank(user);
    vault.deposit{value: ONE_ETHER}(block.timestamp + ONE_WEEK);

    assertEq(vault.getVaultCount(otherUser), 0);
    assertEq(vault.getTotalBalance(otherUser), 0);
  }
}
