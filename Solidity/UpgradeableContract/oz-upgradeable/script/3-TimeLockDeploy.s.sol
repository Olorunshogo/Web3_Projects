// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {TimeLockV1} from "../src/3-TimeLockV1.sol";

contract TimeLockDeployScript is Script {
    function run() external {
        vm.startBroadcast();

        address proxy = Upgrades.deployUUPSProxy(
            "3-TimeLockV1.sol:TimeLockV1",
            abi.encodeCall(TimeLockV1.initialize, (msg.sender))
        );

        console.log("TimeLockV1 proxy deployed at:", proxy);

        vm.stopBroadcast();
    }
}
