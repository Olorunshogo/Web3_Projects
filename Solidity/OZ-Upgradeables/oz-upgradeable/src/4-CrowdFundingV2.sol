// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {CrowdFundingV1} from "./4-CrowdFundingV1.sol";

/// @custom:oz-upgrades-from CrowdFundingV1
contract CrowdFundingV2 is CrowdFundingV1 {
    event DeadlineExtended(uint256 newDeadline);

    /// @notice Owner can extend the deadline while the campaign is active and goal not yet met
    /// @param extraTime Additional seconds to add to the current deadline
    function extendDeadline(uint256 extraTime) external onlyOwner {
        require(vaultStatus == Status.ACTIVE, "Campaign not active");
        require(totalRaised < fundingGoal, "Funding goal already met");
        require(extraTime > 0, "Extra time must be > 0");

        deadline += extraTime;

        emit DeadlineExtended(deadline);
    }
}
