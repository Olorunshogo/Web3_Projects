// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AuctionContractV1} from "./5-AuctionV1.sol";

/// @custom:oz-upgrades-from AuctionContractV1
contract AuctionContractV2 is AuctionContractV1 {
    event AuctionCancelled(uint256 indexed auctionId);

    /// @notice Cancel a Pending or OnGoing auction; refunds the highest bidder if any
    /// @param _auctionId The auction to cancel
    function cancelAuction(uint256 _auctionId) external {
        Auction storage auction = auctions[_auctionId];

        require(msg.sender == auction.owner, "Not your Auction");
        require(
            auction.status == AuctionStatus.Pending || auction.status == AuctionStatus.OnGoing,
            "Cannot cancel"
        );

        auction.status = AuctionStatus.Cancelled;

        // Refund highest bidder if there was one
        if (auction.highestBidder != address(0) && auction.highestBid > 0) {
            refunds[_auctionId][auction.highestBidder] += auction.highestBid;
        }

        emit AuctionCancelled(_auctionId);
    }
}
