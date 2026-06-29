// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTMarketplaceV1 is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuard {
    uint256 public marketplaceFeeBps;
    address public treasury;

    struct Listing {
        address seller;
        uint256 price;
        bool isActive;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;

    event NFTListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event NFTBought(address indexed buyer, address indexed nftAddress, uint256 indexed tokenId, uint256 price, uint256 fee);
    event ListingCancelled(address indexed seller, address indexed nftAddress, uint256 indexed tokenId);
    event MarketplaceFeeUpdated(uint256 newFeeBps);
    event TreasuryUpdated(address newTreasury);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialOwner,
        uint256 _initialFeeBps,
        address _treasury
    ) public initializer {
        __Ownable_init(initialOwner);
        require(_initialFeeBps <= 2500, "Fee too high at launch");
        require(_treasury != address(0), "Invalid treasury address");
        marketplaceFeeBps = _initialFeeBps;
        treasury = _treasury;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function listNFT(address _nftAddress, uint256 _tokenId, uint256 _price) external {
        require(_price > 0, "Price must be > 0 wei");

        IERC721 nft = IERC721(_nftAddress);
        require(nft.ownerOf(_tokenId) == msg.sender, "You are not the owner");
        require(
            nft.getApproved(_tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)),
            "Marketplace must be approved to transfer this NFT"
        );

        listings[_nftAddress][_tokenId] = Listing({seller: msg.sender, price: _price, isActive: true});

        emit NFTListed(msg.sender, _nftAddress, _tokenId, _price);
    }

    function buyNFT(address _nftAddress, uint256 _tokenId) external payable nonReentrant {
        Listing storage listing = listings[_nftAddress][_tokenId];
        require(listing.isActive, "This NFT is not listed anymore");
        require(msg.value >= listing.price, "You didn't send enough ETH");

        uint256 fee = (listing.price * marketplaceFeeBps) / 10_000;
        uint256 sellerGets = listing.price - fee;

        listing.isActive = false;

        IERC721(_nftAddress).safeTransferFrom(listing.seller, msg.sender, _tokenId);

        (bool ok1, ) = payable(listing.seller).call{value: sellerGets}("");
        require(ok1, "Failed to send ETH to seller");

        (bool ok2, ) = payable(treasury).call{value: fee}("");
        require(ok2, "Failed to send fee to treasury");

        if (msg.value > listing.price) {
            uint256 refund = msg.value - listing.price;
            (bool ok3, ) = payable(msg.sender).call{value: refund}("");
            require(ok3, "Refund failed");
        }

        emit NFTBought(msg.sender, _nftAddress, _tokenId, listing.price, fee);
    }

    function cancelListing(address _nftAddress, uint256 _tokenId) external {
        Listing storage listing = listings[_nftAddress][_tokenId];
        require(listing.isActive, "Not listed");
        require(listing.seller == msg.sender, "Only the seller can cancel");

        listing.isActive = false;

        emit ListingCancelled(msg.sender, _nftAddress, _tokenId);
    }

    function updateMarketplaceFee(uint256 _newFeeBps) external onlyOwner {
        require(_newFeeBps <= 10000, "Fee cannot be more than 100%");
        marketplaceFeeBps = _newFeeBps;
        emit MarketplaceFeeUpdated(_newFeeBps);
    }

    function getListingDetails(
        address _nftAddress,
        uint256 _tokenId
    ) external view returns (address seller, uint256 price, bool isActive) {
        Listing memory l = listings[_nftAddress][_tokenId];
        return (l.seller, l.price, l.isActive);
    }

    function getMarketplaceFee() external view returns (uint256) {
        return marketplaceFeeBps;
    }

    function getMarketplaceFeeInPercent() external view returns (uint256) {
        return marketplaceFeeBps / 100;
    }

    function getTreasuryBalance() external view returns (uint256) {
        return address(treasury).balance;
    }

    // Storage gap for future upgrades
    uint256[50] private __gap;
}
