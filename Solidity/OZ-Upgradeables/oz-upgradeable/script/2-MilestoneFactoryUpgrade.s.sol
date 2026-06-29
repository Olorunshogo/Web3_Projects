// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract MilestoneFactoryUpgradeScript is Script {
    function run() external {
        address proxy = vm.envAddress("PROXY_ADDRESS");

        vm.startBroadcast();

        Upgrades.upgradeProxy(proxy, "2-MilestoneFactoryV2.sol:MilestoneFactoryV2", "");

        address impl = Upgrades.getImplementationAddress(proxy);
        console.log("MilestoneFactoryV2 implementation at:", impl);

        vm.stopBroadcast();
    }
}
