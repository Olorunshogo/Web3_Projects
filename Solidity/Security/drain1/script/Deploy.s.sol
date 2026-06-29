// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "../src/BuidlBank.sol";

contract Deploy is Script {
    function run() external payable {
        vm.startBroadcast();

        BuidlBank bank = new BuidlBank{value: 1 ether}();

        vm.stopBroadcast();
    }
}