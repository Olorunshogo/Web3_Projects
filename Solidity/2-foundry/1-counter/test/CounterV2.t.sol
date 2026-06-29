// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import { Test } from "../lib/forge-std/src/Test.sol";
import {CounterV2} from "../src/CounterV2.sol";
import { console } from "../lib/forge-std/src/console.sol";

contract CounterV2Test is Test {
  CounterV2 public counterV2;
  address public owner;
  address public addr1;

  // Deploy contract function
  function setUp() public {
    counterV2 = new CounterV2();
    counterV2.setNumber(0);

    owner = counterV2.owner();
    addr1 = makeAddr("addr1");
  }

  function test_Revert_SetNumber() public {
    vm.prank(addr1);
    uint count1 = counterV2.number();
    console.log("Real contract owner is: ", owner);
    assertEq(count1, 0);

    vm.expectRevert("Not owner");
    counterV2.increment();
    uint count2 = counterV2.number();
    vm.stopPrank();

    assertEq(count2, 1);
  }

  // Successful setNumber
  function test_setNumber() public {
    vm.prank(addr1);
    uint count1 = counterV2.number();
    console.log("Real contract owner is: ", owner);
    assertEq(count1, 0);

    counterV2.increment();
    uint count2 = counterV2.number();
    vm.stopPrank();

    assertEq(count2, 1);
  }

}
