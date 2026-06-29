// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {TodoContractV1} from "../src/1-TodoV1.sol";

contract TodoDeployScript is Script {
    function run() external {
        vm.startBroadcast();

        address proxy = Upgrades.deployUUPSProxy(
            "1-TodoV1.sol:TodoContractV1",
            abi.encodeCall(TodoContractV1.initialize, (msg.sender))
        );

        console.log("TodoContractV1 proxy deployed at:", proxy);

        vm.stopBroadcast();
    }
}
