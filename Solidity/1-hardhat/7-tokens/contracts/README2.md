Prompt for Grok (NFT Marketplace)
Task Overview

Track B involves building a minimal NFT Marketplace contract that allows users to list ERC-721 tokens for sale, buy NFTs, and manage marketplace fees. The contract must support listing, buying, and canceling listings, ensuring that only the owner can list NFTs, and implementing proper handling of the marketplace fee.

We need to deploy and manage the marketplace’s fee structure, transfer of NFTs between buyers and sellers, and ensure that users can cancel or update their listings as needed. Additionally, the contract should be protected against reentrancy attacks and properly handle marketplace fees.

Key Functional Requirements

1. Listing NFTs

The contract should allow users to list ERC-721 tokens.

Only the owner of the NFT (token owner) can list their NFT for sale.

The marketplace must be approved to transfer the listed NFTs.

2. Cancel Listing

Users should be able to cancel their listings.

Only the seller (NFT owner) can cancel the listing.

When a listing is canceled, the NFT must be returned to the seller.

3. Buy NFT

Users can buy a listed NFT.

ETH should be transferred to the seller (minus the marketplace fee).

The marketplace fee should be transferred to the contract owner’s treasury.

After the purchase, the NFT should be transferred to the buyer.

The transaction should be safe against reentrancy attacks.

4. Marketplace Fee

The contract owner can set a marketplace fee (e.g., 2.5%).

The fee should be deducted from the purchase price.

The marketplace fee should be transferred to the treasury.
---
### Advanced Requirements (Bonus)

1. Fee Update

The contract owner should be able to update the marketplace fee.

2. Access Control

Only the contract owner can update the marketplace fee.

3. Reentrancy Protection

Ensure reentrancy is prevented during NFT transactions (e.g., when buying or canceling a listing).
---
### Security Considerations

1. Reentrancy Attack Protection:

Use the checks-effects-interactions pattern for handling ETH transfers and state changes.

Use ReentrancyGuard to prevent reentrancy during sensitive functions (buying or canceling listings).

2. Approval and Transfer Checks:

Ensure that the user has approved the marketplace contract to transfer their NFT before listing it.

Ensure the correct transfer of funds during buying and canceling listings.

3. Edge Case Handling:

Handle cases where the user is trying to buy an NFT that has already been sold or canceled.

Handle cases where a seller tries to cancel a listing that was never made or has already been sold.
---

### Helper Functions

1. getListingDetails(address nftAddress)

This function should return the details of an NFT listing, including the price, seller, and whether the listing is still active.

2. getMarketplaceFee()

This function should return the current marketplace fee percentage.

3. getTreasuryBalance()

This function should return the current balance of the contract’s treasury.
---

### Sample NFT Marketplace Contract Outline
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./IERC721.sol";  // Import ERC721 interface
import "./Ownable.sol";  // Import Ownable for access control

contract NFTMarketplace is Ownable {

    // Marketplace fee in percentage (e.g., 2.5%)
    uint256 public marketplaceFee;
    address public treasury;

    // Mapping to store NFT listings
    mapping(address => mapping(uint256 => Listing)) public listings;

    // Structure to hold listing details
    struct Listing {
        address seller;
        uint256 price;
        bool isActive;
    }

    // Events
    event NFTListed(address indexed seller, address indexed nftAddress, uint256 tokenId, uint256 price);
    event NFTBought(address indexed buyer, address indexed nftAddress, uint256 tokenId, uint256 price);
    event ListingCancelled(address indexed seller, address indexed nftAddress, uint256 tokenId);
    event MarketplaceFeeUpdated(uint256 newFee);

    constructor(uint256 _marketplaceFee, address _treasury) {
        marketplaceFee = _marketplaceFee;
        treasury = _treasury;
    }

    // List NFT for sale
    function listNFT(address _nftAddress, uint256 _tokenId, uint256 _price) external {
        IERC721 nft = IERC721(_nftAddress);
        require(nft.ownerOf(_tokenId) == msg.sender, "Not the owner of this NFT");
        require(nft.isApprovedForAll(msg.sender, address(this)) || nft.getApproved(_tokenId) == address(this), "Marketplace not approved to transfer NFT");

        listings[_nftAddress][_tokenId] = Listing({
            seller: msg.sender,
            price: _price,
            isActive: true
        });

        emit NFTListed(msg.sender, _nftAddress, _tokenId, _price);
    }

    // Buy NFT
    function buyNFT(address _nftAddress, uint256 _tokenId) external payable {
        Listing memory listing = listings[_nftAddress][_tokenId];
        require(listing.isActive, "NFT is not for sale");
        require(msg.value >= listing.price, "Insufficient payment");

        // Deduct marketplace fee
        uint256 fee = (msg.value * marketplaceFee) / 100;
        uint256 sellerAmount = msg.value - fee;

        // Transfer NFT to buyer
        IERC721 nft = IERC721(_nftAddress);
        nft.safeTransferFrom(listing.seller, msg.sender, _tokenId);

        // Transfer funds to seller and fee to treasury
        payable(listing.seller).transfer(sellerAmount);
        payable(treasury).transfer(fee);

        // Mark the listing as inactive
        listings[_nftAddress][_tokenId].isActive = false;

        emit NFTBought(msg.sender, _nftAddress, _tokenId, listing.price);
    }

    // Cancel NFT listing
    function cancelListing(address _nftAddress, uint256 _tokenId) external {
        Listing memory listing = listings[_nftAddress][_tokenId];
        require(listing.seller == msg.sender, "Only seller can cancel listing");
        require(listing.isActive, "NFT is not listed");

        listings[_nftAddress][_tokenId].isActive = false;

        emit ListingCancelled(msg.sender, _nftAddress, _tokenId);
    }

    // Update marketplace fee (only owner)
    function updateMarketplaceFee(uint256 _newFee) external onlyOwner {
        marketplaceFee = _newFee;
        emit MarketplaceFeeUpdated(_newFee);
    }

    // Get marketplace fee
    function getMarketplaceFee() external view returns (uint256) {
        return marketplaceFee;
    }

    // Get treasury balance
    function getTreasuryBalance() external view returns (uint256) {
        return address(treasury).balance;
    }
}
```
---

### Pseudo-Code Solution (Simplified)

1. Initialize Marketplace Contract:

Set the initial marketplace fee and treasury address (where the fee goes).

2. Listing NFTs:

Ensure the seller is the owner of the NFT and that the contract is approved to transfer it.

Create a Listing struct to store the seller, price, and listing status.

3. Buying NFTs:

Check if the NFT is listed and if the buyer has sent enough ETH.

Deduct the marketplace fee, transfer the remaining funds to the seller, and transfer the NFT to the buyer.

Mark the NFT as no longer listed.

4. Cancel Listing:

Only the seller can cancel their listing.

Mark the listing as inactive and return the NFT to the seller.

5. Fee Management:

Only the contract owner can update the marketplace fee.

Track and return the marketplace fee and treasury balance.

6. Reentrancy Protection:

Use the checks-effects-interactions pattern to prevent reentrancy during transfers.
---

### Overview:

The NFT Marketplace contract is more linear and intuitive compared to the DeFi staking protocol. The functionality revolves around handling listings, buying NFTs, and managing a fee structure.

1. Listing: Users list their ERC-721 tokens for sale, ensuring proper approval for the marketplace contract to transfer their NFTs.

2. Buying: Users can buy listed NFTs, with the marketplace fee automatically deducted from the payment.

3. Canceling: Sellers can cancel their listings, ensuring their NFTs are returned to them.

4. Security: The contract avoids reentrancy issues and includes mechanisms for updating fees.

This process is straightforward because it primarily focuses on transferring NFTs between users and managing payments securely.





