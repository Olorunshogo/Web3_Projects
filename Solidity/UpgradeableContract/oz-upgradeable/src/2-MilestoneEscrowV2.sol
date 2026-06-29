// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MilestoneEscrow} from "./2-MilestoneEscrow.sol";

/// @notice V2 escrow with dispute functionality, deployed by MilestoneFactoryV2.
contract MilestoneEscrowV2 is MilestoneEscrow {
    bool public disputed;

    event MilestoneDisputed(address indexed client);
    event DisputeResolved(bool releasedToFreelancer);

    constructor(
        address _client,
        address _freelancer,
        uint256 _totalMilestones,
        uint256 _milestoneAmount,
        uint256 _approvalTimeout
    ) payable MilestoneEscrow(_client, _freelancer, _totalMilestones, _milestoneAmount, _approvalTimeout) {}

    function disputeMilestone() external onlyClient {
        require(status == Status.ACTIVE, "Not active");
        require(!disputed, "Already disputed");
        disputed = true;
        emit MilestoneDisputed(msg.sender);
    }

    function resolveDispute(bool releaseToFreelancer) external onlyClient {
        require(disputed, "Not disputed");
        disputed = false;

        if (releaseToFreelancer) {
            require(releasedMilestones < completedMilestones, "Nothing to release");
            releasedMilestones++;
            (bool ok, ) = freelancer.call{value: milestoneAmount}("");
            require(ok, "ETH transfer failed");
            if (releasedMilestones == totalMilestones) {
                status = Status.COMPLETE;
            }
        } else {
            (bool ok, ) = client.call{value: milestoneAmount}("");
            require(ok, "Refund failed");
        }

        emit DisputeResolved(releaseToFreelancer);
    }

    function approveMilestone() external override onlyClient {
        require(!disputed, "Milestone is disputed");
        _releasePayment();
    }

    function claimTimeoutPayment() external override onlyFreelancer {
        require(!disputed, "Milestone is disputed");
        require(block.timestamp > lastCompletionTime + approvalTimeout, "Timeout not reached");
        _releasePayment();
    }
}
