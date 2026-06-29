// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {NFTMarketplaceV1} from "./6-NFTMarketplaceV1.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @custom:oz-upgrades-from NFTMarketplaceV1
contract NFTMarketplaceV2 is NFTMarketplaceV1 {
    /// @notice Buy multiple active NFT listings in a single transaction
    /// @param nftAddresses Array of NFT contract addresses
    /// @param tokenIds Array of token IDs (must match nftAddresses length)
    function bulkBuyNFTs(
        address[] calldata nftAddresses,
        uint256[] calldata tokenIds
    ) external payable nonReentrant {
        require(nftAddresses.length == tokenIds.length, "Array length mismatch");
        require(nftAddresses.length > 0, "Empty arrays");

        // Calculate total cost first to validate msg.value
        uint256 totalCost = 0;
        for (uint256 i = 0; i < nftAddresses.length; i++) {
            Listing storage listing = listings[nftAddresses[i]][tokenIds[i]];
            require(listing.isActive, "This NFT is not listed anymore");
            totalCost += listing.price;
        }
        require(msg.value >= totalCost, "Insufficient ETH");

        // Execute each purchase
        for (uint256 i = 0; i < nftAddresses.length; i++) {
            Listing storage listing = listings[nftAddresses[i]][tokenIds[i]];

            uint256 fee = (listing.price * marketplaceFeeBps) / 10_000;
            uint256 sellerGets = listing.price - fee;

            listing.isActive = false;

            IERC721(nftAddresses[i]).safeTransferFrom(listing.seller, msg.sender, tokenIds[i]);

            (bool ok1, ) = payable(listing.seller).call{value: sellerGets}("");
            require(ok1, "Failed to send ETH to seller");

            (bool ok2, ) = payable(treasury).call{value: fee}("");
            require(ok2, "Failed to send fee to treasury");

            emit NFTBought(msg.sender, nftAddresses[i], tokenIds[i], listing.price, fee);
        }

        // Refund any excess ETH
        if (msg.value > totalCost) {
            uint256 refund = msg.value - totalCost;
            (bool ok, ) = payable(msg.sender).call{value: refund}("");
            require(ok, "Refund failed");
        }
    }

    /// @notice Owner can update the treasury address
    /// @param newTreasury The new treasury address (must be non-zero)
    function updateTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "Invalid treasury address");
        treasury = newTreasury;
        emit TreasuryUpdated(newTreasury);
    }
}
