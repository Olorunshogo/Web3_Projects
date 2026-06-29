// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MilestoneFactoryV1} from "./2-MilestoneFactoryV1.sol";
import {MilestoneEscrowV2} from "./2-MilestoneEscrowV2.sol";

/// @custom:oz-upgrades-from MilestoneFactoryV1
contract MilestoneFactoryV2 is MilestoneFactoryV1 {
    /// @notice Deploys a MilestoneEscrowV2 (with dispute functionality) instead of V1
    function createEscrow(
        address freelancer,
        uint256 totalMilestones,
        uint256 milestoneAmount,
        uint256 approvalTimeout
    ) external payable override returns (address) {
        MilestoneEscrowV2 escrow = new MilestoneEscrowV2{value: msg.value}(
            msg.sender,
            freelancer,
            totalMilestones,
            milestoneAmount,
            approvalTimeout
        );

        escrows[escrowCount] = address(escrow);
        emit EscrowCreated(escrowCount, address(escrow));
        escrowCount++;

        return address(escrow);
    }
}
