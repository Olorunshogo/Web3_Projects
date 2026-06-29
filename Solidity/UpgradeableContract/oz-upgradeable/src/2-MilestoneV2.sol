// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MilestoneV1} from "./2-MilestoneV1.sol";

/// @custom:oz-upgrades-from MilestoneV1
contract MilestoneV2 is MilestoneV1 {
    bool public disputed;

    event MilestoneDisputed(address indexed client);
    event DisputeResolved(bool releasedToFreelancer);

    /// @notice Client raises a dispute, freezing further payments
    function disputeMilestone() external onlyClient {
        require(status == Status.ACTIVE, "Not active");
        require(!disputed, "Already disputed");
        disputed = true;
        emit MilestoneDisputed(msg.sender);
    }

    /// @notice Client resolves the dispute — either release payment or refund
    /// @param releaseToFreelancer true = pay freelancer, false = refund client
    function resolveDispute(bool releaseToFreelancer) external onlyClient {
        require(disputed, "Not disputed");
        disputed = false;

        if (releaseToFreelancer) {
            // Release one milestone payment to freelancer
            require(releasedMilestones < completedMilestones, "Nothing to release");
            releasedMilestones++;
            (bool ok, ) = freelancer.call{value: milestoneAmount}("");
            require(ok, "ETH transfer failed");
            if (releasedMilestones == totalMilestones) {
                status = Status.COMPLETE;
            }
        } else {
            // Refund one milestone payment to client
            (bool ok, ) = client.call{value: milestoneAmount}("");
            require(ok, "Refund failed");
        }

        emit DisputeResolved(releaseToFreelancer);
    }

    /// @dev Block approvals while disputed
    function approveMilestone() external override onlyClient {
        require(!disputed, "Milestone is disputed");
        _releasePayment();
    }

    /// @dev Block timeout claims while disputed
    function claimTimeoutPayment() external override onlyFreelancer {
        require(!disputed, "Milestone is disputed");
        require(block.timestamp > lastCompletionTime + approvalTimeout, "Timeout not reached");
        _releasePayment();
    }
}
