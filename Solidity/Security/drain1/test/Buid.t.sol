// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.33;

import {Test} from "forge-std/Test.sol";
import {BuidlBank} from "../src/BuildlBank.sol";

contract BuidlBankTest is Test {
    BuidlBank buidlBank;
    address owner = makeAddr("owner");
    address bob = makeAddr("bob");

    function setUp() public {
        vm.deal(owner, 1 ether);
        vm.deal(bob, 1 ether);

        vm.prank(owner);
        buidlBank = new BuidlBank{value: 1 ether}();
    }

    function test_deposit() public {
        vm.startPrank(bob);
        buidlBank.deposit{value: 1 ether}(address(this), 0);
        vm.stopPrank();
    }

    function test_drainOverflow() public {
        vm.startPrank(bob);

        // Overflow value
        uint256 overflowBps = type(uint256).max - buidlBank.feeBps() + 1;

        // Deposit with crafted overflow input
        buidlBank.deposit{value: 1 ether}(bob, overflowBps);

        vm.stopPrank();

        assertEq(buidlBank.viewDeposit(bob), 1 ether);
    }
}
