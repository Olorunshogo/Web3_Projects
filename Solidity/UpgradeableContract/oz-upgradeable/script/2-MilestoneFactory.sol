// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {MilestoneFactoryV1} from "../src/2-MilestoneFactoryV1.sol";

contract MilestoneFactoryScript is Script {
    function run() external {
        vm.startBroadcast();

        address proxy = Upgrades.deployUUPSProxy(
            "2-MilestoneFactoryV1.sol:MilestoneFactoryV1",
            abi.encodeCall(MilestoneFactoryV1.initialize, (msg.sender))
        );

        console.log("MilestoneFactoryV1 proxy deployed at:", proxy);

        vm.stopBroadcast();
    }
}
