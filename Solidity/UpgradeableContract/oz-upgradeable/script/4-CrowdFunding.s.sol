// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {CrowdFundingV1} from "../src/4-CrowdFundingV1.sol";

contract CrowdFundingScript is Script {
    function run() external {
        uint256 fundingGoal = 10 ether;
        uint256 duration = 7 days;

        vm.startBroadcast();

        address proxy = Upgrades.deployUUPSProxy(
            "4-CrowdFundingV1.sol:CrowdFundingV1",
            abi.encodeCall(CrowdFundingV1.initialize, (msg.sender, fundingGoal, duration))
        );

        console.log("CrowdFundingV1 proxy deployed at:", proxy);

        vm.stopBroadcast();
    }
}
