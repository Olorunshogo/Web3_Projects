// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {MilestoneEscrow} from "./2-MilestoneEscrow.sol";

/// @notice Upgradeable factory that deploys plain MilestoneEscrow contracts.
/// The factory itself is a UUPS proxy; individual escrows are not proxied.
contract MilestoneFactoryV1 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    uint256 public escrowCount;
    mapping(uint256 => address) public escrows;

    event EscrowCreated(uint256 indexed id, address escrow);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function createEscrow(
        address freelancer,
        uint256 totalMilestones,
        uint256 milestoneAmount,
        uint256 approvalTimeout
    ) external payable virtual returns (address) {
        MilestoneEscrow escrow = new MilestoneEscrow{value: msg.value}(
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

    // Storage gap for future upgrades
    uint256[50] private __gap;
}
