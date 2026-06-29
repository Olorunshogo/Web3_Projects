// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract TodoUpgradeScript is Script {
    function run() external {
        address proxy = vm.envAddress("PROXY_ADDRESS");

        vm.startBroadcast();

        Upgrades.upgradeProxy(proxy, "1-TodoV2.sol:TodoContractV2", "");

        address impl = Upgrades.getImplementationAddress(proxy);
        console.log("TodoContractV2 implementation at:", impl);

        vm.stopBroadcast();
    }
}
