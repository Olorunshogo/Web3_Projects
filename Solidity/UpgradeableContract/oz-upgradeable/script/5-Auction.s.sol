// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {AuctionContractV1} from "../src/5-AuctionV1.sol";

contract AuctionScript is Script {
    function run() external {
        vm.startBroadcast();

        address proxy = Upgrades.deployUUPSProxy(
            "5-AuctionV1.sol:AuctionContractV1",
            abi.encodeCall(AuctionContractV1.initialize, (msg.sender))
        );

        console.log("AuctionContractV1 proxy deployed at:", proxy);

        vm.stopBroadcast();
    }
}
