// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibMarketplace} from "../libraries/LibMarketplace.sol";

contract MarketplaceFacet {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    modifier nonReentrant() {
        LibMarketplace.MarketplaceStorage storage ms = LibMarketplace.marketplaceStorage();
        require(ms.reentrancyStatus != _ENTERED, "ReentrancyGuard: reentrant call");
        ms.reentrancyStatus = _ENTERED;
        _;
        ms.reentrancyStatus = _NOT_ENTERED;
    }

    // Events
    event NFTListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event NFTBought(address indexed buyer, address indexed nftAddress, uint256 indexed tokenId, uint256 price, uint256 fee);
    event ListingCancelled(address indexed seller, address indexed nftAddress, uint256 indexed tokenId);
    event MarketplaceFeeUpdated(uint256 newFeeBps);
    event TreasuryUpdated(address newTreasury);

    // === 1. List an NFT for sale
    function listNFT(address _nftAddress, uint256 _tokenId, uint256 _price) external {
        LibMarketplace.MarketplaceStorage storage ms = LibMarketplace.marketplaceStorage();
        require(_price > 0, "Price must be > 0 wei");

        IERC721 nft = IERC721(_nftAddress);

        // Only real owner can list
        require(nft.ownerOf(_tokenId) == msg.sender, "You are not the owner");

        // Must have given permission to THIS marketplace contract
        require(
            nft.getApproved(_tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)),
            "Marketplace must be approved to transfer this NFT"
        );

        ms.listings[_nftAddress][_tokenId] = LibMarketplace.Listing({seller: msg.sender, price: _price, isActive: true});

        emit NFTListed(msg.sender, _nftAddress, _tokenId, _price);
    }

    // === Buy a listed NFT ===
    function buyNFT(address _nftAddress, uint256 _tokenId) external payable nonReentrant {
        LibMarketplace.MarketplaceStorage storage ms = LibMarketplace.marketplaceStorage();
        LibMarketplace.Listing storage listing = ms.listings[_nftAddress][_tokenId];
        require(listing.isActive, "This NFT is not listed anymore");

        require(msg.value >= listing.price, "You didn't send enough ETH");

        // Calculate fee using basis points
        uint256 fee = (listing.price * ms.marketplaceFeeBps) / 10_000;
        uint256 sellerGets = listing.price - fee;

        // Effects first (change state before external calls)
        listing.isActive = false;

        // Transfer NFT to buyer (calls onERC721Received if buyer is contract)
        IERC721(_nftAddress).safeTransferFrom(listing.seller, msg.sender, _tokenId);

        // Send money to seller
        (bool ok1, ) = payable(listing.seller).call{value: sellerGets}("");
        require(ok1, "Failed to send ETH to seller");

        // Send fee to treasury
        (bool ok2, ) = payable(ms.treasury).call{value: fee}("");
        require(ok2, "Failed to send fee to treasury");

        // Refund extra ETH if buyer overpaid
        if (msg.value > listing.price) {
            uint256 refund = msg.value - listing.price;
            (bool ok3, ) = payable(msg.sender).call{value: refund}("");
            require(ok3, "Refund failed");
        }

        emit NFTBought(msg.sender, _nftAddress, _tokenId, listing.price, fee);
    }

    // === Cancel your own listing ===
    function cancelListing(address _nftAddress, uint256 _tokenId) external {
        LibMarketplace.MarketplaceStorage storage ms = LibMarketplace.marketplaceStorage();
        LibMarketplace.Listing storage listing = ms.listings[_nftAddress][_tokenId];
        require(listing.isActive, "Not listed");
        require(listing.seller == msg.sender, "Only the seller can cancel");

        listing.isActive = false;

        emit ListingCancelled(msg.sender, _nftAddress, _tokenId);
    }

    // === Owner-only: change fee (in basis points) ===
    function updateMarketplaceFee(uint256 _newFeeBps) external {
        LibMarketplace.MarketplaceStorage storage ms = LibMarketplace.marketplaceStorage();
        LibDiamond.enforceIsContractOwner();
        require(_newFeeBps <= 10000, "Fee cannot be more than 100%");
        ms.marketplaceFeeBps = _newFeeBps;
        emit MarketplaceFeeUpdated(_newFeeBps);
    }

    // === View functions ===
    function getListingDetails(address _nftAddress, uint256 _tokenId) external view returns (address seller, uint256 price, bool isActive) {
        LibMarketplace.MarketplaceStorage storage ms = LibMarketplace.marketplaceStorage();
        LibMarketplace.Listing memory l = ms.listings[_nftAddress][_tokenId];
        return (l.seller, l.price, l.isActive);
    }

    function getMarketplaceFee() external view returns (uint256) {
        LibMarketplace.MarketplaceStorage storage ms = LibMarketplace.marketplaceStorage();
        return ms.marketplaceFeeBps;
    }

    function getMarketplaceFeeInPercent() external view returns (uint256) {
        LibMarketplace.MarketplaceStorage storage ms = LibMarketplace.marketplaceStorage();
        return ms.marketplaceFeeBps / 100;
    }

    function getTreasuryBalance() external view returns (uint256) {
        LibMarketplace.MarketplaceStorage storage ms = LibMarketplace.marketplaceStorage();
        return address(ms.treasury).balance;
    }

    // Getter functions to emulate public state vars
    function marketplaceFeeBps() external view returns (uint256) {
        LibMarketplace.MarketplaceStorage storage ms = LibMarketplace.marketplaceStorage();
        return ms.marketplaceFeeBps;
    }

    function treasury() external view returns (address) {
        LibMarketplace.MarketplaceStorage storage ms = LibMarketplace.marketplaceStorage();
        return ms.treasury;
    }

    function listings(address nftAddress, uint256 tokenId) external view returns (address seller, uint256 price, bool isActive) {
        LibMarketplace.MarketplaceStorage storage ms = LibMarketplace.marketplaceStorage();
        LibMarketplace.Listing memory l = ms.listings[nftAddress][tokenId];
        return (l.seller, l.price, l.isActive);
    }
}
