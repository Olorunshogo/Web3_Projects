// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract CrowdFundingV1 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    uint256 public fundingGoal;
    uint256 public deadline;
    uint256 public totalRaised;

    enum Status {
        NOT_STARTED,
        ACTIVE,
        SUCCESSFUL,
        FAILED
    }

    Status public vaultStatus;

    mapping(address => uint256) public contributions;

    event Log(address indexed user, string message);
    event Contributed(address indexed user, uint256 amount);
    event Withdrawn(address indexed owner, uint256 amount);
    event Refunded(address indexed user, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialOwner,
        uint256 _fundingGoal,
        uint256 _duration
    ) public initializer {
        __Ownable_init(initialOwner);
        fundingGoal = _fundingGoal;
        deadline = block.timestamp + _duration;
        vaultStatus = Status.ACTIVE;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function contribute() external payable {
        require(vaultStatus == Status.ACTIVE, "Chill first, the funding is not active!");
        require(block.timestamp < deadline, "Sorry. Deadline has passed to contribute.");
        require(msg.value > 0, "Too small. Must send ETH > 0");

        contributions[msg.sender] += msg.value;
        totalRaised += msg.value;

        emit Contributed(msg.sender, msg.value);

        if (totalRaised >= fundingGoal) {
            vaultStatus = Status.SUCCESSFUL;
            emit Log(msg.sender, "Funding goal reached");
        }
    }

    function withdrawFunds() external onlyOwner {
        require(vaultStatus == Status.SUCCESSFUL, "Goal !met");

        uint256 balance = address(this).balance;
        vaultStatus = Status.NOT_STARTED;

        (bool success, ) = owner().call{value: balance}("");
        require(success, "Transfer failed");

        emit Withdrawn(owner(), balance);
    }

    function claimRefund() external {
        require(block.timestamp >= deadline, "Deadline not reached");
        require(vaultStatus != Status.SUCCESSFUL, "Goal was met");

        uint256 amount = contributions[msg.sender];
        require(amount > 0, "No contribution so far.");

        contributions[msg.sender] = 0;
        vaultStatus = Status.FAILED;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Refund failed");

        emit Refunded(msg.sender, amount);
    }

    // Storage gap for future upgrades
    uint256[50] private __gap;
}
