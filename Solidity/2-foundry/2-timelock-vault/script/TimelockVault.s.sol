// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {TimelockVault} from "../src/TimelockVault.sol";

contract TimelockVaultScript is Script {
    TimelockVault public timelockVault;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        timelockVault = new TimelockVault();

        vm.stopBroadcast();
    }
}
