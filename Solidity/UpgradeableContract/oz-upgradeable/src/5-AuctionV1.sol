// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract AuctionContractV1 is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuard {
    uint256 public auctionCounter;

    enum AuctionStatus {
        Pending,
        OnGoing,
        Completed,
        Cancelled
    }

    struct Auction {
        uint256 id;
        uint256 startingPrice;
        AuctionStatus status;
        address owner;
        uint256 highestBid;
        address highestBidder;
        uint256 startTime;
        uint256 duration;
    }

    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => mapping(address => uint256)) public refunds;

    event AuctionInitialaized(uint256 id);
    event BidPlaced(uint256 auctionId, address bidder, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function createAuction(uint256 _price, uint256 _duration) public returns (uint256) {
        require(_price > 0, "non zero price");
        require(_duration > 600, "minimum 10mins for auction time");

        auctionCounter++;
        auctions[auctionCounter] = Auction({
            id: auctionCounter,
            startingPrice: _price,
            status: AuctionStatus.Pending,
            owner: msg.sender,
            highestBid: 0,
            highestBidder: address(0),
            startTime: 0,
            duration: _duration
        });

        emit AuctionInitialaized(auctionCounter);
        return auctionCounter;
    }

    function startAuction(uint256 _auctionId) public {
        Auction storage a = auctions[_auctionId];
        require(msg.sender == a.owner, "Not your Auction");
        require(a.status == AuctionStatus.Pending, "invalid auction Status");

        a.status = AuctionStatus.OnGoing;
        a.startTime = block.timestamp;
    }

    function bid(uint256 _auctionId) external payable nonReentrant {
        Auction storage auction = auctions[_auctionId];

        require(auction.id != 0, "Auction does not exist");
        require(auction.status == AuctionStatus.OnGoing, "Auction not active");
        require(block.timestamp <= auction.startTime + auction.duration, "Auction ended");
        require(msg.sender != auction.owner, "Owner cannot bid");
        require(msg.value > 0, "Bid must be greater than zero");

        uint256 currentBid = refunds[_auctionId][msg.sender] + msg.value;

        if (auction.highestBid == 0) {
            require(currentBid >= auction.startingPrice, "Below starting price");
        } else {
            require(currentBid > auction.highestBid, "Bid too low");
        }

        if (auction.highestBidder != address(0) && auction.highestBidder != msg.sender) {
            refunds[_auctionId][auction.highestBidder] += auction.highestBid;
        }

        refunds[_auctionId][msg.sender] = 0;

        emit BidPlaced(_auctionId, msg.sender, currentBid);

        auction.highestBid = currentBid;
        auction.highestBidder = msg.sender;
    }

    function endAuction(uint256 _auctionId) public nonReentrant {
        Auction storage auction = auctions[_auctionId];

        require(
            msg.sender == auction.owner || msg.sender == auction.highestBidder,
            "Not authorized"
        );
        require(auction.status == AuctionStatus.OnGoing, "Auction not ended yet");
        require(block.timestamp >= auction.startTime + auction.duration, "Auction not ended yet");

        auction.status = AuctionStatus.Completed;

        if (auction.highestBid > 0) {
            (bool sent, ) = auction.owner.call{value: auction.highestBid}("");
            require(sent, "Failed to send Ether to owner");
        }
    }

    function withdraw(uint256 _auctionId) external nonReentrant {
        uint256 amount = refunds[_auctionId][msg.sender];
        require(amount > 0, "No funds to withdraw");

        refunds[_auctionId][msg.sender] = 0;

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Transfer failed");
    }

    function refundBidders(uint256 _auctionId, address person) external view returns (uint256) {
        return refunds[_auctionId][person];
    }

    // Storage gap for future upgrades
    uint256[50] private __gap;
}
