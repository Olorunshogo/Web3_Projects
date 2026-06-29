// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {UnsafeUpgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {NFTMarketplaceV1} from "../src/6-NFTMarketplaceV1.sol";
import {NFTMarketplaceV2} from "../src/6-NFTMarketplaceV2.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockNFT is ERC721 {
    constructor() ERC721("TestNFT", "TNFT") {}
    function mint(address to, uint256 tokenId) external { _mint(to, tokenId); }
}

contract NFTMarketplaceTest is Test {
    address owner;
    address seller;
    address buyer;
    address treasury;
    address proxy;
    NFTMarketplaceV1 marketplace;
    MockNFT nft;

    uint256 constant INITIAL_FEE_BPS = 250; // 2.5%
    uint256 constant TOKEN_ID = 1;
    uint256 constant PRICE = 1 ether;

    // Allow this contract to receive ETH
    receive() external payable {}

    function setUp() public {
        owner = address(this);
        seller = makeAddr("seller");
        buyer = makeAddr("buyer");
        treasury = makeAddr("treasury");

        vm.deal(buyer, 100 ether);
        vm.deal(seller, 10 ether);

        nft = new MockNFT();
        nft.mint(seller, TOKEN_ID);

        address impl = address(new NFTMarketplaceV1());
        proxy = UnsafeUpgrades.deployUUPSProxy(
            impl,
            abi.encodeCall(NFTMarketplaceV1.initialize, (owner, INITIAL_FEE_BPS, treasury))
        );
        marketplace = NFTMarketplaceV1(proxy);

        vm.prank(seller);
        nft.approve(address(marketplace), TOKEN_ID);
    }

    // =========================================================
    // Helpers
    // =========================================================

    function _listToken(uint256 tokenId, uint256 price) internal {
        vm.prank(seller);
        marketplace.listNFT(address(nft), tokenId, price);
    }

    // =========================================================
    // 24.1 — V1 Unit Tests
    // =========================================================

    function test_Deployment_SetsOwner() public view {
        assertEq(marketplace.owner(), owner);
    }

    function test_Deployment_SetsFeeBps() public view {
        assertEq(marketplace.marketplaceFeeBps(), INITIAL_FEE_BPS);
    }

    function test_Deployment_SetsTreasury() public view {
        assertEq(marketplace.treasury(), treasury);
    }

    function test_Initialize_RevertIfFeeTooHigh() public {
        address impl = address(new NFTMarketplaceV1());
        vm.expectRevert("Fee too high at launch");
        UnsafeUpgrades.deployUUPSProxy(
            impl,
            abi.encodeCall(NFTMarketplaceV1.initialize, (owner, 2501, treasury))
        );
    }

    function test_Initialize_RevertIfTreasuryZeroAddress() public {
        address impl = address(new NFTMarketplaceV1());
        vm.expectRevert("Invalid treasury address");
        UnsafeUpgrades.deployUUPSProxy(
            impl,
            abi.encodeCall(NFTMarketplaceV1.initialize, (owner, INITIAL_FEE_BPS, address(0)))
        );
    }

    function test_DoubleInit_Reverts() public {
        vm.expectRevert();
        marketplace.initialize(owner, INITIAL_FEE_BPS, treasury);
    }

    // --- listNFT ---

    function test_ListNFT_Successfully() public {
        vm.expectEmit(true, true, true, true);
        emit NFTMarketplaceV1.NFTListed(seller, address(nft), TOKEN_ID, PRICE);

        _listToken(TOKEN_ID, PRICE);

        (address listedSeller, uint256 listedPrice, bool isActive) =
            marketplace.getListingDetails(address(nft), TOKEN_ID);
        assertEq(listedSeller, seller);
        assertEq(listedPrice, PRICE);
        assertTrue(isActive);
    }

    function test_ListNFT_RevertIfPriceIsZero() public {
        vm.prank(seller);
        vm.expectRevert("Price must be > 0 wei");
        marketplace.listNFT(address(nft), TOKEN_ID, 0);
    }

    function test_ListNFT_RevertIfCallerNotOwner() public {
        vm.prank(buyer);
        vm.expectRevert("You are not the owner");
        marketplace.listNFT(address(nft), TOKEN_ID, PRICE);
    }

    function test_ListNFT_RevertIfNotApproved() public {
        vm.prank(seller);
        nft.approve(address(0), TOKEN_ID);

        vm.prank(seller);
        vm.expectRevert("Marketplace must be approved to transfer this NFT");
        marketplace.listNFT(address(nft), TOKEN_ID, PRICE);
    }

    function test_ListNFT_WorksWithApprovalForAll() public {
        vm.startPrank(seller);
        nft.approve(address(0), TOKEN_ID);
        nft.setApprovalForAll(address(marketplace), true);
        marketplace.listNFT(address(nft), TOKEN_ID, PRICE);
        vm.stopPrank();

        (,, bool isActive) = marketplace.getListingDetails(address(nft), TOKEN_ID);
        assertTrue(isActive);
    }

    // --- buyNFT ---

    function test_BuyNFT_ExactPrice() public {
        _listToken(TOKEN_ID, PRICE);

        uint256 fee = (PRICE * INITIAL_FEE_BPS) / 10_000;
        uint256 sellerGets = PRICE - fee;
        uint256 sellerBefore = seller.balance;
        uint256 treasuryBefore = treasury.balance;

        vm.expectEmit(true, true, true, true);
        emit NFTMarketplaceV1.NFTBought(buyer, address(nft), TOKEN_ID, PRICE, fee);

        vm.prank(buyer);
        marketplace.buyNFT{value: PRICE}(address(nft), TOKEN_ID);

        assertEq(nft.ownerOf(TOKEN_ID), buyer);
        (,, bool isActive) = marketplace.getListingDetails(address(nft), TOKEN_ID);
        assertFalse(isActive);
        assertEq(seller.balance - sellerBefore, sellerGets);
        assertEq(treasury.balance - treasuryBefore, fee);
    }

    function test_BuyNFT_OverpaymentRefunded() public {
        _listToken(TOKEN_ID, PRICE);

        uint256 overpay = 2 ether;
        uint256 buyerBefore = buyer.balance;

        vm.prank(buyer);
        marketplace.buyNFT{value: overpay}(address(nft), TOKEN_ID);

        assertApproxEqAbs(buyerBefore - buyer.balance, PRICE, 0.01 ether);
    }

    function test_BuyNFT_RevertIfNotListed() public {
        vm.prank(buyer);
        vm.expectRevert("This NFT is not listed anymore");
        marketplace.buyNFT{value: PRICE}(address(nft), TOKEN_ID);
    }

    function test_BuyNFT_RevertIfInsufficientFunds() public {
        _listToken(TOKEN_ID, PRICE);

        vm.prank(buyer);
        vm.expectRevert("You didn't send enough ETH");
        marketplace.buyNFT{value: 0.5 ether}(address(nft), TOKEN_ID);
    }

    // --- cancelListing ---

    function test_CancelListing_Successfully() public {
        _listToken(TOKEN_ID, PRICE);

        vm.expectEmit(true, true, true, false);
        emit NFTMarketplaceV1.ListingCancelled(seller, address(nft), TOKEN_ID);

        vm.prank(seller);
        marketplace.cancelListing(address(nft), TOKEN_ID);

        (,, bool isActive) = marketplace.getListingDetails(address(nft), TOKEN_ID);
        assertFalse(isActive);
    }

    function test_CancelListing_RevertIfNotListed() public {
        vm.prank(seller);
        vm.expectRevert("Not listed");
        marketplace.cancelListing(address(nft), TOKEN_ID);
    }

    function test_CancelListing_RevertIfNotSeller() public {
        _listToken(TOKEN_ID, PRICE);

        vm.prank(buyer);
        vm.expectRevert("Only the seller can cancel");
        marketplace.cancelListing(address(nft), TOKEN_ID);
    }

    // --- updateMarketplaceFee ---

    function test_UpdateFee_ByOwner() public {
        vm.expectEmit(false, false, false, true);
        emit NFTMarketplaceV1.MarketplaceFeeUpdated(300);

        marketplace.updateMarketplaceFee(300);
        assertEq(marketplace.marketplaceFeeBps(), 300);
    }

    function test_UpdateFee_RevertIfNotOwner() public {
        vm.prank(seller);
        vm.expectRevert();
        marketplace.updateMarketplaceFee(300);
    }

    function test_UpdateFee_RevertIfOver100Percent() public {
        vm.expectRevert("Fee cannot be more than 100%");
        marketplace.updateMarketplaceFee(10_001);
    }

    function test_UpdateFee_AllowsExactly100Percent() public {
        marketplace.updateMarketplaceFee(10_000);
        assertEq(marketplace.marketplaceFeeBps(), 10_000);
    }

    function test_Upgrade_RevertIfNotOwner() public {
        address newImpl = address(new NFTMarketplaceV2());
        vm.prank(seller);
        vm.expectRevert();
        NFTMarketplaceV1(proxy).upgradeToAndCall(newImpl, "");
    }

    // =========================================================
    // 24.2 — Upgrade Path Tests: V1 → V2
    // =========================================================

    function _deployV1WithListings()
        internal
        returns (address _proxy, uint256 tokenId1, uint256 tokenId2)
    {
        tokenId1 = 10;
        tokenId2 = 11;

        MockNFT _nft = new MockNFT();
        _nft.mint(seller, tokenId1);
        _nft.mint(seller, tokenId2);

        address impl = address(new NFTMarketplaceV1());
        _proxy = UnsafeUpgrades.deployUUPSProxy(
            impl,
            abi.encodeCall(NFTMarketplaceV1.initialize, (owner, INITIAL_FEE_BPS, treasury))
        );

        vm.startPrank(seller);
        _nft.approve(address(_proxy), tokenId1);
        _nft.approve(address(_proxy), tokenId2);
        NFTMarketplaceV1(_proxy).listNFT(address(_nft), tokenId1, PRICE);
        NFTMarketplaceV1(_proxy).listNFT(address(_nft), tokenId2, 2 ether);
        vm.stopPrank();

        return (_proxy, tokenId1, tokenId2);
    }

    function test_Upgrade_OwnerPreserved() public {
        (address _proxy,,) = _deployV1WithListings();
        UnsafeUpgrades.upgradeProxy(_proxy, address(new NFTMarketplaceV2()), "");
        assertEq(NFTMarketplaceV2(_proxy).owner(), owner);
    }

    function test_Upgrade_FeeBpsPreserved() public {
        (address _proxy,,) = _deployV1WithListings();
        UnsafeUpgrades.upgradeProxy(_proxy, address(new NFTMarketplaceV2()), "");
        assertEq(NFTMarketplaceV2(_proxy).marketplaceFeeBps(), INITIAL_FEE_BPS);
    }

    function test_Upgrade_TreasuryPreserved() public {
        (address _proxy,,) = _deployV1WithListings();
        UnsafeUpgrades.upgradeProxy(_proxy, address(new NFTMarketplaceV2()), "");
        assertEq(NFTMarketplaceV2(_proxy).treasury(), treasury);
    }

    function test_Upgrade_ActiveListingsPreserved() public {
        MockNFT _nft = new MockNFT();
        uint256 tid = 20;
        _nft.mint(seller, tid);

        address impl = address(new NFTMarketplaceV1());
        address _proxy = UnsafeUpgrades.deployUUPSProxy(
            impl,
            abi.encodeCall(NFTMarketplaceV1.initialize, (owner, INITIAL_FEE_BPS, treasury))
        );

        vm.startPrank(seller);
        _nft.approve(_proxy, tid);
        NFTMarketplaceV1(_proxy).listNFT(address(_nft), tid, PRICE);
        vm.stopPrank();

        (address s1, uint256 p1, bool a1) = NFTMarketplaceV1(_proxy).getListingDetails(address(_nft), tid);

        UnsafeUpgrades.upgradeProxy(_proxy, address(new NFTMarketplaceV2()), "");

        (address s2, uint256 p2, bool a2) = NFTMarketplaceV2(_proxy).getListingDetails(address(_nft), tid);
        assertEq(s2, s1);
        assertEq(p2, p1);
        assertEq(a2, a1);
        assertTrue(a2);
    }

    // --- bulkBuyNFTs ---

    function test_BulkBuyNFTs_HappyPath() public {
        MockNFT _nft = new MockNFT();
        uint256 tid1 = 30;
        uint256 tid2 = 31;
        _nft.mint(seller, tid1);
        _nft.mint(seller, tid2);

        address impl = address(new NFTMarketplaceV1());
        address _proxy = UnsafeUpgrades.deployUUPSProxy(
            impl,
            abi.encodeCall(NFTMarketplaceV1.initialize, (owner, INITIAL_FEE_BPS, treasury))
        );

        vm.startPrank(seller);
        _nft.approve(_proxy, tid1);
        _nft.approve(_proxy, tid2);
        NFTMarketplaceV1(_proxy).listNFT(address(_nft), tid1, PRICE);
        NFTMarketplaceV1(_proxy).listNFT(address(_nft), tid2, 2 ether);
        vm.stopPrank();

        UnsafeUpgrades.upgradeProxy(_proxy, address(new NFTMarketplaceV2()), "");
        NFTMarketplaceV2 marketplaceV2 = NFTMarketplaceV2(_proxy);

        address[] memory nftAddresses = new address[](2);
        nftAddresses[0] = address(_nft);
        nftAddresses[1] = address(_nft);
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = tid1;
        tokenIds[1] = tid2;

        uint256 totalCost = PRICE + 2 ether;
        vm.prank(buyer);
        marketplaceV2.bulkBuyNFTs{value: totalCost}(nftAddresses, tokenIds);

        assertEq(_nft.ownerOf(tid1), buyer);
        assertEq(_nft.ownerOf(tid2), buyer);
        (,, bool a1) = marketplaceV2.getListingDetails(address(_nft), tid1);
        (,, bool a2) = marketplaceV2.getListingDetails(address(_nft), tid2);
        assertFalse(a1);
        assertFalse(a2);
    }

    function test_BulkBuyNFTs_RefundsExcessETH() public {
        MockNFT _nft = new MockNFT();
        uint256 tid = 40;
        _nft.mint(seller, tid);

        address impl = address(new NFTMarketplaceV1());
        address _proxy = UnsafeUpgrades.deployUUPSProxy(
            impl,
            abi.encodeCall(NFTMarketplaceV1.initialize, (owner, INITIAL_FEE_BPS, treasury))
        );

        vm.startPrank(seller);
        _nft.approve(_proxy, tid);
        NFTMarketplaceV1(_proxy).listNFT(address(_nft), tid, PRICE);
        vm.stopPrank();

        UnsafeUpgrades.upgradeProxy(_proxy, address(new NFTMarketplaceV2()), "");
        NFTMarketplaceV2 marketplaceV2 = NFTMarketplaceV2(_proxy);

        address[] memory nftAddresses = new address[](1);
        nftAddresses[0] = address(_nft);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tid;

        uint256 excess = 0.5 ether;
        uint256 buyerBefore = buyer.balance;

        vm.prank(buyer);
        marketplaceV2.bulkBuyNFTs{value: PRICE + excess}(nftAddresses, tokenIds);

        assertApproxEqAbs(buyerBefore - buyer.balance, PRICE, 0.01 ether);
    }

    function test_BulkBuyNFTs_RevertIfArrayLengthMismatch() public {
        UnsafeUpgrades.upgradeProxy(proxy, address(new NFTMarketplaceV2()), "");
        NFTMarketplaceV2 marketplaceV2 = NFTMarketplaceV2(proxy);

        address[] memory nftAddresses = new address[](2);
        uint256[] memory tokenIds = new uint256[](1);

        vm.prank(buyer);
        vm.expectRevert("Array length mismatch");
        marketplaceV2.bulkBuyNFTs{value: 1 ether}(nftAddresses, tokenIds);
    }

    function test_BulkBuyNFTs_RevertIfInsufficientETH() public {
        MockNFT _nft = new MockNFT();
        uint256 tid = 50;
        _nft.mint(seller, tid);

        address impl = address(new NFTMarketplaceV1());
        address _proxy = UnsafeUpgrades.deployUUPSProxy(
            impl,
            abi.encodeCall(NFTMarketplaceV1.initialize, (owner, INITIAL_FEE_BPS, treasury))
        );

        vm.startPrank(seller);
        _nft.approve(_proxy, tid);
        NFTMarketplaceV1(_proxy).listNFT(address(_nft), tid, PRICE);
        vm.stopPrank();

        UnsafeUpgrades.upgradeProxy(_proxy, address(new NFTMarketplaceV2()), "");
        NFTMarketplaceV2 marketplaceV2 = NFTMarketplaceV2(_proxy);

        address[] memory nftAddresses = new address[](1);
        nftAddresses[0] = address(_nft);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tid;

        vm.prank(buyer);
        vm.expectRevert("Insufficient ETH");
        marketplaceV2.bulkBuyNFTs{value: 0.5 ether}(nftAddresses, tokenIds);
    }

    function test_BulkBuyNFTs_RevertIfNFTNotListed() public {
        MockNFT _nft = new MockNFT();
        uint256 tid = 60;
        _nft.mint(seller, tid);

        address impl = address(new NFTMarketplaceV1());
        address _proxy = UnsafeUpgrades.deployUUPSProxy(
            impl,
            abi.encodeCall(NFTMarketplaceV1.initialize, (owner, INITIAL_FEE_BPS, treasury))
        );

        UnsafeUpgrades.upgradeProxy(_proxy, address(new NFTMarketplaceV2()), "");
        NFTMarketplaceV2 marketplaceV2 = NFTMarketplaceV2(_proxy);

        address[] memory nftAddresses = new address[](1);
        nftAddresses[0] = address(_nft);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tid;

        vm.prank(buyer);
        vm.expectRevert("This NFT is not listed anymore");
        marketplaceV2.bulkBuyNFTs{value: 1 ether}(nftAddresses, tokenIds);
    }

    // --- updateTreasury ---

    function test_UpdateTreasury_HappyPath() public {
        UnsafeUpgrades.upgradeProxy(proxy, address(new NFTMarketplaceV2()), "");
        NFTMarketplaceV2 marketplaceV2 = NFTMarketplaceV2(proxy);

        address newTreasury = makeAddr("newTreasury");

        vm.expectEmit(false, false, false, true);
        emit NFTMarketplaceV1.TreasuryUpdated(newTreasury);

        marketplaceV2.updateTreasury(newTreasury);
        assertEq(marketplaceV2.treasury(), newTreasury);
    }

    function test_UpdateTreasury_RevertIfZeroAddress() public {
        UnsafeUpgrades.upgradeProxy(proxy, address(new NFTMarketplaceV2()), "");
        NFTMarketplaceV2 marketplaceV2 = NFTMarketplaceV2(proxy);

        vm.expectRevert("Invalid treasury address");
        marketplaceV2.updateTreasury(address(0));
    }

    function test_UpdateTreasury_RevertIfNotOwner() public {
        UnsafeUpgrades.upgradeProxy(proxy, address(new NFTMarketplaceV2()), "");
        NFTMarketplaceV2 marketplaceV2 = NFTMarketplaceV2(proxy);

        vm.prank(seller);
        vm.expectRevert();
        marketplaceV2.updateTreasury(makeAddr("newTreasury"));
    }

    // =========================================================
    // 24.3 — Fuzz Test: bulkBuyNFTs Total Cost Equals Sum of Prices
    // Feature: oz-upgradeable-v1-v2, Property 8: bulkBuyNFTs Total Cost Equals Sum of Prices
    // =========================================================

    function test_fuzz_NFTMarketplace_BulkBuyCostEqualsSum(uint256 price1, uint256 price2) public {
        // Bound price1, price2 to [1, 10 ether]
        price1 = bound(price1, 1, 10 ether);
        price2 = bound(price2, 1, 10 ether);

        MockNFT _nft = new MockNFT();
        uint256 tid1 = 100;
        uint256 tid2 = 101;
        _nft.mint(seller, tid1);
        _nft.mint(seller, tid2);

        address impl = address(new NFTMarketplaceV1());
        address _proxy = UnsafeUpgrades.deployUUPSProxy(
            impl,
            abi.encodeCall(NFTMarketplaceV1.initialize, (owner, INITIAL_FEE_BPS, treasury))
        );

        vm.startPrank(seller);
        _nft.approve(_proxy, tid1);
        _nft.approve(_proxy, tid2);
        NFTMarketplaceV1(_proxy).listNFT(address(_nft), tid1, price1);
        NFTMarketplaceV1(_proxy).listNFT(address(_nft), tid2, price2);
        vm.stopPrank();

        UnsafeUpgrades.upgradeProxy(_proxy, address(new NFTMarketplaceV2()), "");
        NFTMarketplaceV2 marketplaceV2 = NFTMarketplaceV2(_proxy);

        address[] memory nftAddresses = new address[](2);
        nftAddresses[0] = address(_nft);
        nftAddresses[1] = address(_nft);
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = tid1;
        tokenIds[1] = tid2;

        uint256 totalCost = price1 + price2;
        vm.deal(buyer, totalCost + 1 ether);

        uint256 buyerBefore = buyer.balance;

        vm.prank(buyer);
        marketplaceV2.bulkBuyNFTs{value: totalCost}(nftAddresses, tokenIds);

        // Buyer balance delta should equal price1 + price2 (sent exactly that, no refund)
        assertEq(buyerBefore - buyer.balance, totalCost);
    }
}
