// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Plain (non-upgradeable) escrow contract deployed by MilestoneFactory.
/// Individual escrows are not proxied — only the factory is upgradeable.
contract MilestoneEscrow {
    address public client;
    address public freelancer;
    uint256 public totalMilestones;
    uint256 public milestoneAmount;
    uint256 public approvalTimeout;

    uint256 public completedMilestones;
    uint256 public releasedMilestones;
    uint256 public lastCompletionTime;

    enum Status { ACTIVE, COMPLETE }
    Status public status;

    modifier onlyClient() {
        require(msg.sender == client, "Only client");
        _;
    }

    modifier onlyFreelancer() {
        require(msg.sender == freelancer, "Only freelancer");
        _;
    }

    constructor(
        address _client,
        address _freelancer,
        uint256 _totalMilestones,
        uint256 _milestoneAmount,
        uint256 _approvalTimeout
    ) payable {
        require(msg.value == _totalMilestones * _milestoneAmount, "Incorrect funding");
        client = _client;
        freelancer = _freelancer;
        totalMilestones = _totalMilestones;
        milestoneAmount = _milestoneAmount;
        approvalTimeout = _approvalTimeout;
        status = Status.ACTIVE;
    }

    function markMilestoneCompleted() external onlyFreelancer {
        require(status == Status.ACTIVE, "Not active");
        require(completedMilestones < totalMilestones, "All completed");
        completedMilestones++;
        lastCompletionTime = block.timestamp;
    }

    function approveMilestone() external virtual onlyClient {
        _releasePayment();
    }

    function claimTimeoutPayment() external virtual onlyFreelancer {
        require(block.timestamp > lastCompletionTime + approvalTimeout, "Timeout not reached");
        _releasePayment();
    }

    function _releasePayment() internal virtual {
        require(status == Status.ACTIVE, "Not active");
        require(releasedMilestones < completedMilestones, "Nothing to release");
        releasedMilestones++;
        (bool ok, ) = freelancer.call{value: milestoneAmount}("");
        require(ok, "ETH transfer failed");
        if (releasedMilestones == totalMilestones) {
            status = Status.COMPLETE;
        }
    }
}
