import { expect } from "chai";
import { network } from "hardhat";

const { ethers } = await network.connect();

describe("NFTMarketplace", function () {
  let nftMarketplace: any;
  let mockERC721: any;
  let owner: any;
  let seller: any;
  let buyer: any;
  let treasury: any;
  let otherUser: any;
  let treasuryAddress: string;
  const initialFeeBps = 250; // 2.5%
  const tokenId = 1;
  const price = ethers.parseEther("1"); // 1 ETH

  beforeEach(async function () {
    // === Get signers
    [owner, seller, buyer, treasury, otherUser] = await ethers.getSigners();
    treasuryAddress = ethers.Wallet.createRandom().address; // New treasury each time

    // === Deploy mock ERC721 for testing
    const MockERC721 = await ethers.getContractFactory("ERC721");
    mockERC721 = await MockERC721.deploy("TestNFT", "TNFT", "");

    // === Mint NFT to seller
    await mockERC721.mint(seller.address, tokenId);

    // === Deploy NFTMarketplace
    const NFTMarketplace = await ethers.getContractFactory("NFTMarketplace");
    nftMarketplace = await NFTMarketplace.deploy(initialFeeBps, treasuryAddress);

    // === Approve marketplace to transfer NFT
    await mockERC721.connect(seller).approve(nftMarketplace.target, tokenId);
  });

  describe("Constructor", function () {
    it("Should deploy with correct initial values", async function () {
      expect(await nftMarketplace.marketplaceFeeBps()).to.equal(initialFeeBps);
      expect(await nftMarketplace.treasury()).to.equal(treasuryAddress);
      expect(await nftMarketplace.owner()).to.equal(owner.address);
    });

    it("Should revert if initial fee is too high", async function () {
      const NFTMarketplace = await ethers.getContractFactory("NFTMarketplace");
      await expect(NFTMarketplace.deploy(2501, treasury.address)).to.be.revertedWith("Fee too high at launch");
    });

    it("Should revert if treasury is zero address", async function () {
      const NFTMarketplace = await ethers.getContractFactory("NFTMarketplace");
      await expect(NFTMarketplace.deploy(initialFeeBps, ethers.ZeroAddress)).to.be.revertedWith("Invalid treasury address");
    });
  });

  // === List NFTs
  describe("listNFT", function () {
    it("Should list NFT successfully", async function () {
      await expect(nftMarketplace.connect(seller).listNFT(mockERC721.target, tokenId, price))
        .to.emit(nftMarketplace, "NFTListed")
        .withArgs(seller.address, mockERC721.target, tokenId, price);

      const listing = await nftMarketplace.listings(mockERC721.target, tokenId);
      expect(listing.seller).to.equal(seller.address);
      expect(listing.price).to.equal(price);
      expect(listing.isActive).to.be.true;
    });

    it("Should revert if price is zero", async function () {
      await expect(nftMarketplace.connect(seller).listNFT(mockERC721.target, tokenId, 0))
        .to.be.revertedWith("Price must be > 0 wei");
    });

    it("Should revert if caller is not the owner", async function () {
      await expect(nftMarketplace.connect(buyer).listNFT(mockERC721.target, tokenId, price))
        .to.be.revertedWith("You are not the owner");
    });

    it("Should revert if marketplace is not approved", async function () {
      // === Revoke approval
      await mockERC721.connect(seller).approve(ethers.ZeroAddress, tokenId);
      await expect(nftMarketplace.connect(seller).listNFT(mockERC721.target, tokenId, price))
        .to.be.revertedWith("Marketplace must be approved to transfer this NFT");
    });

    it("Should revert if approved for all but not for this token", async function () {
      // === Approve for all, but revoke specific approval
      await mockERC721.connect(seller).setApprovalForAll(nftMarketplace.target, true);
      await mockERC721.connect(seller).approve(ethers.ZeroAddress, tokenId);

      // ===This should still work because isApprovedForAll is true
      await expect(nftMarketplace.connect(seller).listNFT(mockERC721.target, tokenId, price))
        .to.not.revert;
    });

    it("Should allow listing the same NFT again after previous listing is inactive", async function () {
      // === List first time
      await nftMarketplace.connect(seller).listNFT(mockERC721.target, tokenId, price);

      // === Cancel listing
      await nftMarketplace.connect(seller).cancelListing(mockERC721.target, tokenId);

      // === List again
      const newPrice = ethers.parseEther("2");
      await expect(nftMarketplace.connect(seller).listNFT(mockERC721.target, tokenId, newPrice))
        .to.emit(nftMarketplace, "NFTListed")
        .withArgs(seller.address, mockERC721.target, tokenId, newPrice);

      const listing = await nftMarketplace.listings(mockERC721.target, tokenId);
      expect(listing.price).to.equal(newPrice);
    });
  });

  // === Buy NFTs
  describe("buyNFT", function () {
    beforeEach(async function () {
      // === List the NFT
      await nftMarketplace.connect(seller).listNFT(mockERC721.target, tokenId, price);
    });

    it("Should buy NFT successfully with exact price", async function () {
      const fee = (price * BigInt(initialFeeBps)) / 10000n;
      const sellerGets = price - fee;

      const sellerBalanceBefore = await ethers.provider.getBalance(seller.address);
      const treasuryBalanceBefore = await ethers.provider.getBalance(treasuryAddress);
      const buyerBalanceBefore = await ethers.provider.getBalance(buyer.address);

      await expect(nftMarketplace.connect(buyer).buyNFT(mockERC721.target, tokenId, { value: price }))
        .to.emit(nftMarketplace, "NFTBought")
        .withArgs(buyer.address, mockERC721.target, tokenId, price, fee);

      // Check NFT ownership
      expect(await mockERC721.ownerOf(tokenId)).to.equal(buyer.address);

      // Check listing is inactive
      const listing = await nftMarketplace.listings(mockERC721.target, tokenId);
      expect(listing.isActive).to.be.false;

      // Check balances (approximately, due to gas costs)
      const sellerBalanceAfter = await ethers.provider.getBalance(seller.address);
      const treasuryBalanceAfter = await ethers.provider.getBalance(treasuryAddress);

      expect(sellerBalanceAfter - sellerBalanceBefore).to.be.closeTo(sellerGets, ethers.parseEther("0.01")); // Allow for gas
      expect(treasuryBalanceAfter - treasuryBalanceBefore).to.equal(fee);
    });

    it("Should buy NFT with overpayment and refund extra", async function () {
      const overpay = ethers.parseEther("2");
      const refund = overpay - price;

      const buyerBalanceBefore = await ethers.provider.getBalance(buyer.address);

      await nftMarketplace.connect(buyer).buyNFT(mockERC721.target, tokenId, { value: overpay });

      const buyerBalanceAfter = await ethers.provider.getBalance(buyer.address);
      // Buyer should get refund minus gas
      expect(buyerBalanceBefore - buyerBalanceAfter).to.be.closeTo(price, ethers.parseEther("0.01"));
    });

    it("Should revert if NFT is not listed", async function () {
      // Cancel the listing
      await nftMarketplace.connect(seller).cancelListing(mockERC721.target, tokenId);

      await expect(nftMarketplace.connect(buyer).buyNFT(mockERC721.target, tokenId, { value: price }))
        .to.be.revertedWith("This NFT is not listed anymore");
    });

    it("Should revert if insufficient funds", async function () {
      const insufficientAmount = ethers.parseEther("0.5");

      await expect(nftMarketplace.connect(buyer).buyNFT(mockERC721.target, tokenId, { value: insufficientAmount }))
        .to.be.revertedWith("You didn't send enough ETH");
    });

    it("Should handle fee calculation correctly", async function () {
      // Test with different fee
      await nftMarketplace.connect(owner).updateMarketplaceFee(500); // 5%

      const newFee = (price * 500n) / 10000n;
      const sellerGets = price - newFee;

      await nftMarketplace.connect(buyer).buyNFT(mockERC721.target, tokenId, { value: price });

      const treasuryBalanceAfter = await ethers.provider.getBalance(treasuryAddress);
      expect(treasuryBalanceAfter).to.equal(newFee);
    });
  });

  // === Cancel Listing
  describe("cancelListing", function () {
    beforeEach(async function () {
      // === List the NFT
      await nftMarketplace.connect(seller).listNFT(mockERC721.target, tokenId, price);
    });

    it("Should cancel listing successfully", async function () {
      await expect(nftMarketplace.connect(seller).cancelListing(mockERC721.target, tokenId))
        .to.emit(nftMarketplace, "ListingCancelled")
        .withArgs(seller.address, mockERC721.target, tokenId);

      const listing = await nftMarketplace.listings(mockERC721.target, tokenId);
      expect(listing.isActive).to.be.false;
    });

    it("Should revert if caller is not the seller", async function () {
      await expect(nftMarketplace.connect(buyer).cancelListing(mockERC721.target, tokenId))
        .to.be.revertedWith("Only the seller can cancel");
    });

    it("Should revert if NFT is not listed", async function () {
      // Cancel first
      await nftMarketplace.connect(seller).cancelListing(mockERC721.target, tokenId);

      // Try to cancel again
      await expect(nftMarketplace.connect(seller).cancelListing(mockERC721.target, tokenId))
        .to.be.revertedWith("Not listed");
    });
  });

  // === Update Marketplace
  describe("updateMarketplaceFee", function () {
    it("Should update fee successfully by owner", async function () {
      const newFee = 300;

      await expect(nftMarketplace.connect(owner).updateMarketplaceFee(newFee))
        .to.emit(nftMarketplace, "MarketplaceFeeUpdated")
        .withArgs(newFee);

      expect(await nftMarketplace.marketplaceFeeBps()).to.equal(newFee);
    });

    it("Should revert if caller is not owner", async function () {
      await expect(nftMarketplace.connect(seller).updateMarketplaceFee(300))
        .to.be.revertedWithCustomError(nftMarketplace, "OwnableUnauthorizedAccount");
    });

    it("Should revert if fee is over 100%", async function () {
      await expect(nftMarketplace.connect(owner).updateMarketplaceFee(10001))
        .to.be.revertedWith("Fee cannot be more than 100%");
    });

    it("Should allow fee of 100%", async function () {
      await nftMarketplace.connect(owner).updateMarketplaceFee(10000);
      expect(await nftMarketplace.marketplaceFeeBps()).to.equal(10000);
    });
  });

  // === View Functions
  describe("View Functions", function () {
    beforeEach(async function () {
      // === List the NFT
      await nftMarketplace.connect(seller).listNFT(mockERC721.target, tokenId, price);
    });

    it("getListingDetails should return correct details", async function () {
      const [sellerAddr, listingPrice, isActive] = await nftMarketplace.getListingDetails(mockERC721.target, tokenId);

      expect(sellerAddr).to.equal(seller.address);
      expect(listingPrice).to.equal(price);
      expect(isActive).to.be.true;
    });

    it("getMarketplaceFee should return fee in bps", async function () {
      expect(await nftMarketplace.getMarketplaceFee()).to.equal(initialFeeBps);
    });

    it("getMarketplaceFeeInPercent should return fee in percent", async function () {
      expect(await nftMarketplace.getMarketplaceFeeInPercent()).to.equal(2); // 250 bps = 2%
    });

    it("getTreasuryBalance should return treasury balance", async function () {
      // === Send some ETH to treasury for testing
      await owner.sendTransaction({ to: treasuryAddress, value: ethers.parseEther("1") });

      expect(await nftMarketplace.getTreasuryBalance()).to.equal(ethers.parseEther("1"));
    });
  });

  // === Integrations Tests
  describe("Integration Tests", function () {
    it("Complete flow: list, buy, and verify state changes", async function () {
      // === List NFT
      await nftMarketplace.connect(seller).listNFT(mockERC721.target, tokenId, price);

      // === Verify listing
      let listing = await nftMarketplace.listings(mockERC721.target, tokenId);
      expect(listing.isActive).to.be.true;
      expect(await mockERC721.ownerOf(tokenId)).to.equal(seller.address);

      // === Buy NFT
      await nftMarketplace.connect(buyer).buyNFT(mockERC721.target, tokenId, { value: price });

      // === Verify purchase
      expect(await mockERC721.ownerOf(tokenId)).to.equal(buyer.address);
      listing = await nftMarketplace.listings(mockERC721.target, tokenId);
      expect(listing.isActive).to.be.false;
    });

    it("Should handle multiple listings", async function () {
      // === Mint another NFT
      const tokenId2 = 2;
      await mockERC721.mint(seller.address, tokenId2);
      await mockERC721.connect(seller).approve(nftMarketplace.target, tokenId2);

      const price2 = ethers.parseEther("2");

      // === List both NFTs
      await nftMarketplace.connect(seller).listNFT(mockERC721.target, tokenId, price);
      await nftMarketplace.connect(seller).listNFT(mockERC721.target, tokenId2, price2);

      // === Buy first NFT
      await nftMarketplace.connect(buyer).buyNFT(mockERC721.target, tokenId, { value: price });

      // === Check that second listing is still active
      const listing2 = await nftMarketplace.listings(mockERC721.target, tokenId2);
      expect(listing2.isActive).to.be.true;
    });
  });
});