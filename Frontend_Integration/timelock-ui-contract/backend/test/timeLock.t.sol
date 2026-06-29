// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Test} from "forge-std/Test.sol";
import {TimelockSavings} from "../src/timeLock.sol";

contract TimelockSavingsTest is Test {
    TimelockSavings public timelock;
    address public user = address(0x1);

    function setUp() public {
        timelock = new TimelockSavings();
        vm.deal(user, 10 ether);
    }

    function testDeposit() public {
        uint256 unlockTime = block.timestamp + 1 days;
        
        vm.prank(user);
        timelock.deposit{value: 1 ether}(unlockTime);

        (uint256 amount, uint256 unlock, bool active) = timelock.getVault(user);
        assertEq(amount, 1 ether);
        assertEq(unlock, unlockTime);
        assertTrue(active);
    }

    function testCannotDepositZero() public {
        vm.prank(user);
        vm.expectRevert("Send ETH");
        timelock.deposit{value: 0}(block.timestamp + 1 days);
    }

    function testCannotDepositTwice() public {
        uint256 unlockTime = block.timestamp + 1 days;
        
        vm.prank(user);
        timelock.deposit{value: 1 ether}(unlockTime);

        vm.prank(user);
        vm.expectRevert("Vault active");
        timelock.deposit{value: 1 ether}(unlockTime);
    }

    function testWithdrawAfterUnlock() public {
        uint256 unlockTime = block.timestamp + 1 days;
        
        vm.prank(user);
        timelock.deposit{value: 1 ether}(unlockTime);

        vm.warp(unlockTime);
        
        vm.prank(user);
        timelock.withdraw();

        (uint256 amount, , bool active) = timelock.getVault(user);
        assertEq(amount, 0);
        assertFalse(active);
        assertEq(user.balance, 10 ether);
    }

    function testCannotWithdrawBeforeUnlock() public {
        uint256 unlockTime = block.timestamp + 1 days;
        
        vm.prank(user);
        timelock.deposit{value: 1 ether}(unlockTime);

        vm.prank(user);
        vm.expectRevert("Too early");
        timelock.withdraw();
    }

    function testCannotWithdrawWithoutVault() public {
        vm.prank(user);
        vm.expectRevert("No vault");
        timelock.withdraw();
    }
}
