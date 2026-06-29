// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {NFTMarketplaceV1} from "../src/6-NFTMarketplaceV1.sol";

contract NFTMarketplaceDeployScript is Script {
    function run() external {
        uint256 initialFeeBps = 250; // 2.5%
        address treasury = vm.envAddress("TREASURY_ADDRESS");

        vm.startBroadcast();

        address proxy = Upgrades.deployUUPSProxy(
            "6-NFTMarketplaceV1.sol:NFTMarketplaceV1",
            abi.encodeCall(NFTMarketplaceV1.initialize, (msg.sender, initialFeeBps, treasury))
        );

        console.log("NFTMarketplaceV1 proxy deployed at:", proxy);

        vm.stopBroadcast();
    }
}
