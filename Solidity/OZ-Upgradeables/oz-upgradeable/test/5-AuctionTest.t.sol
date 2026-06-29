// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {UnsafeUpgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {AuctionContractV1} from "../src/5-AuctionV1.sol";
import {AuctionContractV2} from "../src/5-AuctionV2.sol";

contract AuctionTest is Test {
    address owner;
    address bidder1;
    address bidder2;
    address proxy;
    AuctionContractV1 auction;

    uint256 constant STARTING_PRICE = 2 ether;
    uint256 constant DURATION = 3600; // > 600

    // Allow this contract to receive ETH (needed for endAuction payout)
    receive() external payable {}

    function setUp() public {
        owner = address(this);
        bidder1 = makeAddr("bidder1");
        bidder2 = makeAddr("bidder2");

        vm.deal(bidder1, 100 ether);
        vm.deal(bidder2, 100 ether);

        address impl = address(new AuctionContractV1());
        proxy = UnsafeUpgrades.deployUUPSProxy(
            impl,
            abi.encodeCall(AuctionContractV1.initialize, (owner))
        );
        auction = AuctionContractV1(proxy);
    }

    // =========================================================
    // Helpers
    // =========================================================

    function _createAuction() internal returns (uint256 auctionId) {
        auction.createAuction(STARTING_PRICE, DURATION);
        auctionId = auction.auctionCounter();
    }

    function _createAndStart() internal returns (uint256 auctionId) {
        auctionId = _createAuction();
        auction.startAuction(auctionId);
    }

    // Returns (proxy, auctionId, bidAmount) with bidder1 having placed the first bid
    function _deployWithBid()
        internal
        returns (address _proxy, uint256 auctionId, uint256 bidAmount)
    {
        address impl = address(new AuctionContractV1());
        _proxy = UnsafeUpgrades.deployUUPSProxy(
            impl,
            abi.encodeCall(AuctionContractV1.initialize, (owner))
        );

        AuctionContractV1(_proxy).createAuction(STARTING_PRICE, DURATION);
        auctionId = AuctionContractV1(_proxy).auctionCounter();
        AuctionContractV1(_proxy).startAuction(auctionId);

        bidAmount = STARTING_PRICE;
        vm.prank(bidder1);
        AuctionContractV1(_proxy).bid{value: bidAmount}(auctionId);
    }

    // =========================================================
    // 23.1 — V1 Unit Tests
    // =========================================================

    function test_Deployment_SetsOwner() public view {
        assertEq(auction.owner(), owner);
    }

    function test_Deployment_AuctionCounterStartsAtZero() public view {
        assertEq(auction.auctionCounter(), 0);
    }

    function test_CreateAuction_EmitsEventAndIncrementsCounter() public {
        vm.expectEmit(false, false, false, true);
        emit AuctionContractV1.AuctionInitialaized(1);
        auction.createAuction(STARTING_PRICE, DURATION);
        assertEq(auction.auctionCounter(), 1);
    }

    function test_CreateAuction_StoresCorrectState() public {
        uint256 auctionId = _createAuction();
        (uint256 id, uint256 startingPrice, , address auctionOwner, , , , uint256 duration) =
            auction.auctions(auctionId);
        assertEq(id, auctionId);
        assertEq(startingPrice, STARTING_PRICE);
        assertEq(auctionOwner, owner);
        assertEq(duration, DURATION);
    }

    function test_CreateAuction_InitialStatusIsPending() public {
        uint256 auctionId = _createAuction();
        (, , AuctionContractV1.AuctionStatus status, , , , , ) = auction.auctions(auctionId);
        assertEq(uint8(status), 0); // Pending
    }

    function test_CreateAuction_RevertIfZeroPrice() public {
        vm.expectRevert("non zero price");
        auction.createAuction(0, DURATION);
    }

    function test_CreateAuction_RevertIfDurationTooShort() public {
        vm.expectRevert("minimum 10mins for auction time");
        auction.createAuction(STARTING_PRICE, 600);
    }

    function test_StartAuction_SetsStatusOnGoing() public {
        uint256 auctionId = _createAuction();
        auction.startAuction(auctionId);
        (, , AuctionContractV1.AuctionStatus status, , , , , ) = auction.auctions(auctionId);
        assertEq(uint8(status), 1); // OnGoing
    }

    function test_StartAuction_SetsStartTime() public {
        uint256 auctionId = _createAuction();
        auction.startAuction(auctionId);
        (, , , , , , uint256 startTime, ) = auction.auctions(auctionId);
        assertApproxEqAbs(startTime, block.timestamp, 5);
    }

    function test_StartAuction_RevertIfNotOwner() public {
        uint256 auctionId = _createAuction();
        vm.prank(bidder1);
        vm.expectRevert("Not your Auction");
        auction.startAuction(auctionId);
    }

    function test_StartAuction_RevertIfAlreadyStarted() public {
        uint256 auctionId = _createAndStart();
        vm.expectRevert("invalid auction Status");
        auction.startAuction(auctionId);
    }

    function test_Bid_FirstBidAtStartingPrice() public {
        uint256 auctionId = _createAndStart();
        vm.prank(bidder1);
        auction.bid{value: STARTING_PRICE}(auctionId);
        (, , , , uint256 highestBid, address highestBidder, , ) = auction.auctions(auctionId);
        assertEq(highestBid, STARTING_PRICE);
        assertEq(highestBidder, bidder1);
    }

    function test_Bid_EmitsBidPlacedEvent() public {
        uint256 auctionId = _createAndStart();
        vm.expectEmit(true, true, false, true);
        emit AuctionContractV1.BidPlaced(auctionId, bidder1, STARTING_PRICE);
        vm.prank(bidder1);
        auction.bid{value: STARTING_PRICE}(auctionId);
    }

    function test_Bid_RefundsPreviousHighestBidder() public {
        uint256 auctionId = _createAndStart();
        vm.prank(bidder1);
        auction.bid{value: STARTING_PRICE}(auctionId);
        vm.prank(bidder2);
        auction.bid{value: 3 ether}(auctionId);
        assertEq(auction.refunds(auctionId, bidder1), STARTING_PRICE);
    }

    function test_Bid_RevertIfAuctionDoesNotExist() public {
        vm.prank(bidder1);
        vm.expectRevert("Auction does not exist");
        auction.bid{value: STARTING_PRICE}(999);
    }

    function test_Bid_RevertIfAuctionNotOnGoing() public {
        uint256 auctionId = _createAuction();
        vm.prank(bidder1);
        vm.expectRevert("Auction not active");
        auction.bid{value: STARTING_PRICE}(auctionId);
    }

    function test_Bid_RevertIfAuctionEnded() public {
        uint256 auctionId = _createAndStart();
        vm.warp(block.timestamp + DURATION + 1);
        vm.prank(bidder1);
        vm.expectRevert("Auction ended");
        auction.bid{value: STARTING_PRICE}(auctionId);
    }

    function test_Bid_RevertIfOwnerBids() public {
        uint256 auctionId = _createAndStart();
        vm.expectRevert("Owner cannot bid");
        auction.bid{value: STARTING_PRICE}(auctionId);
    }

    function test_Bid_RevertIfZeroValue() public {
        uint256 auctionId = _createAndStart();
        vm.prank(bidder1);
        vm.expectRevert("Bid must be greater than zero");
        auction.bid{value: 0}(auctionId);
    }

    function test_Bid_RevertIfBelowStartingPrice() public {
        uint256 auctionId = _createAndStart();
        vm.prank(bidder1);
        vm.expectRevert("Below starting price");
        auction.bid{value: 1 ether}(auctionId);
    }

    function test_Bid_RevertIfBidTooLow() public {
        uint256 auctionId = _createAndStart();
        vm.prank(bidder1);
        auction.bid{value: STARTING_PRICE}(auctionId);
        vm.prank(bidder2);
        vm.expectRevert("Bid too low");
        auction.bid{value: 1 ether}(auctionId);
    }

    function test_EndAuction_TransfersFundsToOwner() public {
        uint256 auctionId = _createAndStart();
        vm.prank(bidder1);
        auction.bid{value: STARTING_PRICE}(auctionId);
        vm.warp(block.timestamp + DURATION + 1);
        uint256 balanceBefore = owner.balance;
        auction.endAuction(auctionId);
        assertEq(owner.balance - balanceBefore, STARTING_PRICE);
    }

    function test_EndAuction_SetsStatusToCompleted() public {
        uint256 auctionId = _createAndStart();
        vm.prank(bidder1);
        auction.bid{value: STARTING_PRICE}(auctionId);
        vm.warp(block.timestamp + DURATION + 1);
        auction.endAuction(auctionId);
        (, , AuctionContractV1.AuctionStatus status, , , , , ) = auction.auctions(auctionId);
        assertEq(uint8(status), 2); // Completed
    }

    function test_EndAuction_RevertIfNotEnded() public {
        uint256 auctionId = _createAndStart();
        vm.prank(bidder1);
        auction.bid{value: STARTING_PRICE}(auctionId);
        vm.expectRevert("Auction not ended yet");
        auction.endAuction(auctionId);
    }

    function test_EndAuction_RevertIfNotAuthorized() public {
        uint256 auctionId = _createAndStart();
        vm.prank(bidder1);
        auction.bid{value: STARTING_PRICE}(auctionId);
        vm.warp(block.timestamp + DURATION + 1);
        vm.prank(bidder2);
        vm.expectRevert("Not authorized");
        auction.endAuction(auctionId);
    }

    function test_Withdraw_AllowsOutbidBidderToWithdraw() public {
        uint256 auctionId = _createAndStart();
        vm.prank(bidder1);
        auction.bid{value: STARTING_PRICE}(auctionId);
        vm.prank(bidder2);
        auction.bid{value: 3 ether}(auctionId);
        uint256 balanceBefore = bidder1.balance;
        vm.prank(bidder1);
        auction.withdraw(auctionId);
        assertEq(bidder1.balance - balanceBefore, STARTING_PRICE);
        assertEq(auction.refunds(auctionId, bidder1), 0);
    }

    function test_Withdraw_RevertIfNoFunds() public {
        uint256 auctionId = _createAndStart();
        vm.prank(bidder1);
        vm.expectRevert("No funds to withdraw");
        auction.withdraw(auctionId);
    }

    function test_RefundBidders_ReturnsCorrectAmount() public {
        uint256 auctionId = _createAndStart();
        vm.prank(bidder1);
        auction.bid{value: STARTING_PRICE}(auctionId);
        vm.prank(bidder2);
        auction.bid{value: 3 ether}(auctionId);
        assertEq(auction.refundBidders(auctionId, bidder1), STARTING_PRICE);
    }

    function test_RefundBidders_ReturnsZeroIfNoPendingRefund() public view {
        assertEq(auction.refundBidders(1, bidder1), 0);
    }

    function test_DoubleInit_Reverts() public {
        vm.expectRevert();
        auction.initialize(owner);
    }

    function test_Upgrade_RevertIfNotOwner() public {
        address newImpl = address(new AuctionContractV2());
        vm.prank(bidder1);
        vm.expectRevert();
        AuctionContractV1(proxy).upgradeToAndCall(newImpl, "");
    }

    // =========================================================
    // 23.2 — Upgrade Path Tests: V1 → V2
    // =========================================================

    function test_Upgrade_AuctionIdPreserved() public {
        (address _proxy, uint256 auctionId, ) = _deployWithBid();
        UnsafeUpgrades.upgradeProxy(_proxy, address(new AuctionContractV2()), "");
        (uint256 id, , , , , , , ) = AuctionContractV2(_proxy).auctions(auctionId);
        assertEq(id, auctionId);
    }

    function test_Upgrade_AuctionStartingPricePreserved() public {
        (address _proxy, uint256 auctionId, ) = _deployWithBid();
        UnsafeUpgrades.upgradeProxy(_proxy, address(new AuctionContractV2()), "");
        (, uint256 startingPrice, , , , , , ) = AuctionContractV2(_proxy).auctions(auctionId);
        assertEq(startingPrice, STARTING_PRICE);
    }

    function test_Upgrade_AuctionStatusPreserved() public {
        (address _proxy, uint256 auctionId, ) = _deployWithBid();
        UnsafeUpgrades.upgradeProxy(_proxy, address(new AuctionContractV2()), "");
        (, , AuctionContractV2.AuctionStatus status, , , , , ) =
            AuctionContractV2(_proxy).auctions(auctionId);
        assertEq(uint8(status), 1); // OnGoing
    }

    function test_Upgrade_AuctionHighestBidPreserved() public {
        (address _proxy, uint256 auctionId, uint256 bidAmount) = _deployWithBid();
        UnsafeUpgrades.upgradeProxy(_proxy, address(new AuctionContractV2()), "");
        (, , , , uint256 highestBid, address highestBidder, , ) =
            AuctionContractV2(_proxy).auctions(auctionId);
        assertEq(highestBid, bidAmount);
        assertEq(highestBidder, bidder1);
    }

    function test_Upgrade_RefundBalancesPreserved() public {
        (address _proxy, uint256 auctionId, ) = _deployWithBid();
        // bidder2 outbids bidder1 so bidder1 has a pending refund
        vm.prank(bidder2);
        AuctionContractV1(_proxy).bid{value: 3 ether}(auctionId);
        uint256 refundBefore = AuctionContractV1(_proxy).refunds(auctionId, bidder1);
        UnsafeUpgrades.upgradeProxy(_proxy, address(new AuctionContractV2()), "");
        assertEq(AuctionContractV2(_proxy).refunds(auctionId, bidder1), refundBefore);
        assertEq(AuctionContractV2(_proxy).refunds(auctionId, bidder1), STARTING_PRICE);
    }

    function test_Upgrade_OwnerPreserved() public {
        (address _proxy, , ) = _deployWithBid();
        UnsafeUpgrades.upgradeProxy(_proxy, address(new AuctionContractV2()), "");
        assertEq(AuctionContractV2(_proxy).owner(), owner);
    }

    function test_Upgrade_AuctionCounterPreserved() public {
        (address _proxy, uint256 auctionId, ) = _deployWithBid();
        UnsafeUpgrades.upgradeProxy(_proxy, address(new AuctionContractV2()), "");
        assertEq(AuctionContractV2(_proxy).auctionCounter(), auctionId);
    }

    function test_CancelAuction_OnGoingWithBidder_SetsStatusAndCreditsRefund() public {
        (address _proxy, uint256 auctionId, uint256 bidAmount) = _deployWithBid();
        UnsafeUpgrades.upgradeProxy(_proxy, address(new AuctionContractV2()), "");
        AuctionContractV2 auctionV2 = AuctionContractV2(_proxy);

        vm.expectEmit(true, false, false, false);
        emit AuctionContractV2.AuctionCancelled(auctionId);

        auctionV2.cancelAuction(auctionId);

        (, , AuctionContractV2.AuctionStatus status, , , , , ) = auctionV2.auctions(auctionId);
        assertEq(uint8(status), 3); // Cancelled
        assertEq(auctionV2.refunds(auctionId, bidder1), bidAmount);
    }

    function test_CancelAuction_PendingWithoutBidder_SetsStatusCancelled() public {
        address impl = address(new AuctionContractV1());
        address _proxy = UnsafeUpgrades.deployUUPSProxy(
            impl,
            abi.encodeCall(AuctionContractV1.initialize, (owner))
        );
        AuctionContractV1(_proxy).createAuction(STARTING_PRICE, DURATION);
        uint256 auctionId = AuctionContractV1(_proxy).auctionCounter();
        // Do NOT start or bid — auction stays Pending

        UnsafeUpgrades.upgradeProxy(_proxy, address(new AuctionContractV2()), "");
        AuctionContractV2 auctionV2 = AuctionContractV2(_proxy);

        auctionV2.cancelAuction(auctionId);

        (, , AuctionContractV2.AuctionStatus status, , , , , ) = auctionV2.auctions(auctionId);
        assertEq(uint8(status), 3); // Cancelled
        assertEq(auctionV2.refunds(auctionId, bidder1), 0); // no bidder, no refund
    }

    function test_CancelAuction_RevertIfNotOwner() public {
        (address _proxy, uint256 auctionId, ) = _deployWithBid();
        UnsafeUpgrades.upgradeProxy(_proxy, address(new AuctionContractV2()), "");
        AuctionContractV2 auctionV2 = AuctionContractV2(_proxy);
        vm.prank(bidder1);
        vm.expectRevert("Not your Auction");
        auctionV2.cancelAuction(auctionId);
    }

    function test_CancelAuction_RevertIfCompleted() public {
        (address _proxy, uint256 auctionId, ) = _deployWithBid();
        vm.warp(block.timestamp + DURATION + 1);
        AuctionContractV1(_proxy).endAuction(auctionId);
        UnsafeUpgrades.upgradeProxy(_proxy, address(new AuctionContractV2()), "");
        AuctionContractV2 auctionV2 = AuctionContractV2(_proxy);
        vm.expectRevert("Cannot cancel");
        auctionV2.cancelAuction(auctionId);
    }

    function test_CancelAuction_RevertIfAlreadyCancelled() public {
        (address _proxy, uint256 auctionId, ) = _deployWithBid();
        UnsafeUpgrades.upgradeProxy(_proxy, address(new AuctionContractV2()), "");
        AuctionContractV2 auctionV2 = AuctionContractV2(_proxy);
        auctionV2.cancelAuction(auctionId);
        vm.expectRevert("Cannot cancel");
        auctionV2.cancelAuction(auctionId);
    }

    // =========================================================
    // 23.3 — Fuzz Test: cancelAuction Always Credits the Highest Bidder
    // Feature: oz-upgradeable-v1-v2, Property 7: cancelAuction Always Credits the Highest Bidder
    // =========================================================

    function test_fuzz_Auction_CancelAlwaysRefundsBidder(uint256 bidAmount) public {
        // Bound bidAmount to [startingPrice, 100 ether]
        bidAmount = bound(bidAmount, STARTING_PRICE, 100 ether);

        vm.deal(bidder1, bidAmount + 1 ether);

        address impl = address(new AuctionContractV1());
        address _proxy = UnsafeUpgrades.deployUUPSProxy(
            impl,
            abi.encodeCall(AuctionContractV1.initialize, (owner))
        );

        AuctionContractV1(_proxy).createAuction(STARTING_PRICE, DURATION);
        uint256 auctionId = AuctionContractV1(_proxy).auctionCounter();
        AuctionContractV1(_proxy).startAuction(auctionId);

        vm.prank(bidder1);
        AuctionContractV1(_proxy).bid{value: bidAmount}(auctionId);

        UnsafeUpgrades.upgradeProxy(_proxy, address(new AuctionContractV2()), "");
        AuctionContractV2 auctionV2 = AuctionContractV2(_proxy);

        auctionV2.cancelAuction(auctionId);

        // Assert refunds[auctionId][bidder1] == bidAmount
        assertEq(auctionV2.refunds(auctionId, bidder1), bidAmount);
    }
}
