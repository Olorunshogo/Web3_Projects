// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract CrowdFundingUpgradeScript is Script {
    function run() external {
        address proxy = vm.envAddress("PROXY_ADDRESS");

        vm.startBroadcast();

        Upgrades.upgradeProxy(proxy, "4-CrowdFundingV2.sol:CrowdFundingV2", "");

        address impl = Upgrades.getImplementationAddress(proxy);
        console.log("CrowdFundingV2 implementation at:", impl);

        vm.stopBroadcast();
    }
}
