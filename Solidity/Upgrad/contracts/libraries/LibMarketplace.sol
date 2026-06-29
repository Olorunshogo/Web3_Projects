// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibDiamond} from "./LibDiamond.sol";

library LibMarketplace {
    bytes32 constant MARKETPLACE_STORAGE_POSITION = keccak256("marketplace.storage");

    struct Listing {
        address seller;
        uint256 price; // Asking price in wei
        bool isActive; // true = for sale, false = sold or cancelled
    }

    struct MarketplaceStorage {
        uint256 marketplaceFeeBps;
        address treasury;
        mapping(address => mapping(uint256 => Listing)) listings;
        uint256 reentrancyStatus;
    }

    function marketplaceStorage() internal pure returns (MarketplaceStorage storage ms) {
        bytes32 position = MARKETPLACE_STORAGE_POSITION;
        assembly {
            ms.slot := position
        }
    }

    function enforceIsContractOwner() internal view {
        LibDiamond.enforceIsContractOwner();
    }
}
