// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Script} from "forge-std/Script.sol";
import {TimelockSavings} from "../src/timeLock.sol";

contract DeployTimelockSavings is Script {
    function run() external returns (TimelockSavings) {
        vm.startBroadcast();
        TimelockSavings timelock = new TimelockSavings();
        vm.stopBroadcast();
        return timelock;
    }
}
