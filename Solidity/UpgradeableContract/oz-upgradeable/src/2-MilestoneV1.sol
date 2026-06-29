// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract MilestoneV1 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    // Previously immutable — now regular storage variables
    address public client;
    address public freelancer;
    uint256 public totalMilestones;
    uint256 public milestoneAmount;
    uint256 public approvalTimeout;

    uint256 public completedMilestones;
    uint256 public releasedMilestones;
    uint256 public lastCompletionTime;

    enum Status {
        ACTIVE,
        COMPLETE
    }

    Status public status;

    modifier onlyClient() {
        require(msg.sender == client, "Only client");
        _;
    }

    modifier onlyFreelancer() {
        require(msg.sender == freelancer, "Only freelancer");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _client,
        address _freelancer,
        uint256 _totalMilestones,
        uint256 _milestoneAmount,
        uint256 _approvalTimeout
    ) public payable initializer {
        require(msg.value == _totalMilestones * _milestoneAmount, "Incorrect funding");
        __Ownable_init(_client);

        client = _client;
        freelancer = _freelancer;
        totalMilestones = _totalMilestones;
        milestoneAmount = _milestoneAmount;
        approvalTimeout = _approvalTimeout;
        status = Status.ACTIVE;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

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

    // Storage gap for future upgrades
    uint256[50] private __gap;
}
