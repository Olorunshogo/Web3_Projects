// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract NFTMarketplaceUpgradeScript is Script {
    function run() external {
        address proxy = vm.envAddress("PROXY_ADDRESS");

        vm.startBroadcast();

        Upgrades.upgradeProxy(proxy, "6-NFTMarketplaceV2.sol:NFTMarketplaceV2", "");

        address impl = Upgrades.getImplementationAddress(proxy);
        console.log("NFTMarketplaceV2 implementation at:", impl);

        vm.stopBroadcast();
    }
}
