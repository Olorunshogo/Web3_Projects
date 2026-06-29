// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {CounterV3} from "../src/CounterV3.sol";

contract CounterScript is Script {
    CounterV3 public counterV3;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        counterV3 = new CounterV3();

        vm.stopBroadcast();
    }
}
