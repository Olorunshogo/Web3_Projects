// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721, IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract NFTMarketplace is Ownable {
  uint256 public marketplaceFeeBps;

  // Treasury = wallet that receives the marketplace fees
  address public treasury;

  // === Listing storage ===
  // NFT contract address -> token ID -> Listing details
  mapping(address => mapping(uint256 => Listing)) public listings;

  struct Listing {
    address seller;
    uint256 price; // Asking price in wei
    bool isActive; // true = for sale, false = sold or cancelled
  }

  // Events (these help indexers & frontends track what happened)
  event NFTListed(
    address indexed seller,
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price
  );
  event NFTBought(
    address indexed buyer,
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price,
    uint256 fee
  );
  event ListingCancelled(
    address indexed seller,
    address indexed nftAddress,
    uint256 indexed tokenId
  );
  event MarketplaceFeeUpdated(uint256 newFeeBps);
  event TreasuryUpdated(address newTreasury);

  constructor(uint256 _initialFeeBps, address _treasury) Ownable(msg.sender) {
    require(_initialFeeBps <= 2500, "Fee too high at launch"); // Example: max 25% to start
    require(_treasury != address(0), "Invalid treasury address");
    marketplaceFeeBps = _initialFeeBps;
    treasury = _treasury;
  }

  // === 1. List an NFT for sale
  function listNFT(address _nftAddress, uint256 _tokenId, uint256 _price) external {
    require(_price > 0, "Price must be > 0 wei");

    IERC721 nft = IERC721(_nftAddress);

    // Only real owner can list
    require(nft.ownerOf(_tokenId) == msg.sender, "You are not the owner");

    // Must have given permission to THIS marketplace contract
    // 1. Approve each token
    // 2. Approve all token by msg.sender
    require(
      nft.getApproved(_tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)),
      "Marketplace must be approved to transfer this NFT"
    );

    listings[_nftAddress][_tokenId] = Listing({seller: msg.sender, price: _price, isActive: true});

    emit NFTListed(msg.sender, _nftAddress, _tokenId, _price);
  }

  // === Buy a listed NFT ===
  function buyNFT(address _nftAddress, uint256 _tokenId) external payable {
    Listing storage listing = listings[_nftAddress][_tokenId];
    require(listing.isActive, "This NFT is not listed anymore");

    require(msg.value >= listing.price, "You didn't send enough ETH");

    // Calculate fee using basis points
    // Example: 250 bps = 2.5% → fee = (listing.price * 250) / 10_000
    uint256 fee = (listing.price * marketplaceFeeBps) / 10_000;
    uint256 sellerGets = listing.price - fee;

    // Effects first (change state before external calls)
    listing.isActive = false;

    // Transfer NFT to buyer (calls onERC721Received if buyer is contract)
    IERC721(_nftAddress).safeTransferFrom(listing.seller, msg.sender, _tokenId);

    // Send money to seller
    (bool ok1, ) = payable(listing.seller).call{value: sellerGets}("");
    require(ok1, "Failed to send ETH to seller");

    // Send fee to treasury
    (bool ok2, ) = payable(treasury).call{value: fee}("");
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
    Listing storage listing = listings[_nftAddress][_tokenId];
    require(listing.isActive, "Not listed");
    require(listing.seller == msg.sender, "Only the seller can cancel");

    listing.isActive = false;

    emit ListingCancelled(msg.sender, _nftAddress, _tokenId);
  }

  // === Owner-only: change fee (in basis points) ===
  function updateMarketplaceFee(uint256 _newFeeBps) external onlyOwner {
    require(_newFeeBps <= 10000, "Fee cannot be more than 100%");
    marketplaceFeeBps = _newFeeBps;
    emit MarketplaceFeeUpdated(_newFeeBps);
  }

  // === View functions ===
  function getListingDetails(
    address _nftAddress,
    uint256 _tokenId
  ) external view returns (address seller, uint256 price, bool isActive) {
    Listing memory l = listings[_nftAddress][_tokenId];
    return (l.seller, l.price, l.isActive);
  }

  function getMarketplaceFee() external view returns (uint256) {
    return marketplaceFeeBps; // returns bps, e.g. 250 = 2.5%
  }

  function getMarketplaceFeeInPercent() external view returns (uint256) {
    return marketplaceFeeBps / 100; // e.g. 2 (for frontend display)
  }

  function getTreasuryBalance() external view returns (uint256) {
    return address(treasury).balance;
  }
}
