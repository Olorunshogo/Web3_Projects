import { expect } from "chai";
import pkg from "hardhat";
const { ethers } = pkg;
import { deployDiamond } from "../scripts/deploy.cjs";

describe("NFTMarketplaceDiamond", function () {
  let diamondAddress: string;
  let marketplaceFacet: any;
  let mockERC721: any;
  let owner: any;
  let seller: any;
  let buyer: any;
  let treasury: any;
  let otherUser: any;
  let treasuryAddress: string;
  const initialFeeBps = 250; // 2.5%
  const tokenId = 1;
  const price = ethers.utils.parseEther("1"); // 1 ETH

  before(async function () {
    // Deploy diamond
    diamondAddress = await deployDiamond();
  });

  beforeEach(async function () {
    // === Get signers
    [owner, seller, buyer, treasury, otherUser] = await ethers.getSigners();

    // === Deploy mock ERC721 for testing
    const MockERC721 = await ethers.getContractFactory("MockERC721");
    mockERC721 = await MockERC721.deploy(
      "TestNFT",
      "TNFT",
      "https://example.com/"
    );

    // === Mint NFT to seller
    await mockERC721.mint(seller.address, tokenId);

    // === Get MarketplaceFacet attached to diamond
    const MarketplaceFacet = await ethers.getContractFactory(
      "MarketplaceFacet"
    );
    marketplaceFacet = MarketplaceFacet.attach(diamondAddress);
    treasuryAddress = await marketplaceFacet.treasury();

    // Ensure fee is reset for tests that assume the initial value
    const currentFee = await marketplaceFacet.marketplaceFeeBps();
    if (!currentFee.eq(initialFeeBps)) {
      await marketplaceFacet.connect(owner).updateMarketplaceFee(initialFeeBps);
    }

    // === Approve marketplace to transfer NFT
    await mockERC721.connect(seller).approve(diamondAddress, tokenId);
  });

  describe("Constructor", function () {
    it("Should deploy with correct initial values", async function () {
      expect(await marketplaceFacet.marketplaceFeeBps()).to.equal(
        initialFeeBps
      );
      expect(await marketplaceFacet.treasury()).to.equal(treasuryAddress);
      // Owner check via OwnershipFacet
      const OwnershipFacet = await ethers.getContractFactory("OwnershipFacet");
      const ownershipFacet = OwnershipFacet.attach(diamondAddress);
      expect(await ownershipFacet.owner()).to.equal(owner.address);
    });
  });

  // === List NFTs
  describe("listNFT", function () {
    it("Should list NFT successfully", async function () {
      await expect(
        marketplaceFacet
          .connect(seller)
          .listNFT(mockERC721.address, tokenId, price)
      )
        .to.emit(marketplaceFacet, "NFTListed")
        .withArgs(seller.address, mockERC721.address, tokenId, price);

      const listing = await marketplaceFacet.listings(
        mockERC721.address,
        tokenId
      );
      expect(listing.seller).to.equal(seller.address);
      expect(listing.price).to.equal(price);
      expect(listing.isActive).to.be.true;
    });

    it("Should revert if price is zero", async function () {
      await expect(
        marketplaceFacet.connect(seller).listNFT(mockERC721.address, tokenId, 0)
      ).to.be.revertedWith("Price must be > 0 wei");
    });

    it("Should revert if caller is not the owner", async function () {
      await expect(
        marketplaceFacet
          .connect(buyer)
          .listNFT(mockERC721.address, tokenId, price)
      ).to.be.revertedWith("You are not the owner");
    });

    it("Should revert if marketplace is not approved", async function () {
      // === Revoke approval
      await mockERC721
        .connect(seller)
        .approve(ethers.constants.AddressZero, tokenId);
      await expect(
        marketplaceFacet
          .connect(seller)
          .listNFT(mockERC721.address, tokenId, price)
      ).to.be.revertedWith("Marketplace must be approved to transfer this NFT");
    });

    it("Should allow listing the same NFT again after previous listing is inactive", async function () {
      // === List first time
      await marketplaceFacet
        .connect(seller)
        .listNFT(mockERC721.address, tokenId, price);

      // === Cancel listing
      await marketplaceFacet
        .connect(seller)
        .cancelListing(mockERC721.address, tokenId);

      // === List again
      const newPrice = ethers.utils.parseEther("2");
      await expect(
        marketplaceFacet
          .connect(seller)
          .listNFT(mockERC721.address, tokenId, newPrice)
      )
        .to.emit(marketplaceFacet, "NFTListed")
        .withArgs(seller.address, mockERC721.address, tokenId, newPrice);

      const listing = await marketplaceFacet.listings(
        mockERC721.address,
        tokenId
      );
      expect(listing.price).to.equal(newPrice);
    });
  });

  // === Buy NFTs
  describe("buyNFT", function () {
    beforeEach(async function () {
      // === List the NFT
      await marketplaceFacet
        .connect(seller)
        .listNFT(mockERC721.address, tokenId, price);
    });

    it("Should buy NFT successfully with exact price", async function () {
      const fee = price.mul(initialFeeBps).div(10000);
      const sellerGets = price.sub(fee);

      const sellerBalanceBefore = await ethers.provider.getBalance(
        seller.address
      );
      const treasuryBalanceBefore = await ethers.provider.getBalance(
        treasuryAddress
      );
      const buyerBalanceBefore = await ethers.provider.getBalance(
        buyer.address
      );

      await expect(
        marketplaceFacet
          .connect(buyer)
          .buyNFT(mockERC721.address, tokenId, { value: price })
      )
        .to.emit(marketplaceFacet, "NFTBought")
        .withArgs(buyer.address, mockERC721.address, tokenId, price, fee);

      // Check NFT ownership
      expect(await mockERC721.ownerOf(tokenId)).to.equal(buyer.address);

      // Check listing is inactive
      const listing = await marketplaceFacet.listings(
        mockERC721.address,
        tokenId
      );
      expect(listing.isActive).to.be.false;

      // Check balances (approximately, due to gas costs)
      const sellerBalanceAfter = await ethers.provider.getBalance(
        seller.address
      );
      const treasuryBalanceAfter = await ethers.provider.getBalance(
        treasuryAddress
      );

      expect(sellerBalanceAfter.sub(sellerBalanceBefore)).to.be.closeTo(
        sellerGets,
        ethers.utils.parseEther("0.01")
      ); // Allow for gas
      expect(treasuryBalanceAfter.sub(treasuryBalanceBefore)).to.equal(fee);
    });

    it("Should buy NFT with overpayment and refund extra", async function () {
      const overpay = ethers.utils.parseEther("2");
      const refund = overpay.sub(price);

      const buyerBalanceBefore = await ethers.provider.getBalance(
        buyer.address
      );

      await marketplaceFacet
        .connect(buyer)
        .buyNFT(mockERC721.address, tokenId, { value: overpay });

      const buyerBalanceAfter = await ethers.provider.getBalance(buyer.address);
      // Buyer should get refund minus gas
      expect(buyerBalanceBefore.sub(buyerBalanceAfter)).to.be.closeTo(
        price,
        ethers.utils.parseEther("0.01")
      );
    });

    it("Should revert if NFT is not listed", async function () {
      // Cancel the listing
      await marketplaceFacet
        .connect(seller)
        .cancelListing(mockERC721.address, tokenId);

      await expect(
        marketplaceFacet
          .connect(buyer)
          .buyNFT(mockERC721.address, tokenId, { value: price })
      ).to.be.revertedWith("This NFT is not listed anymore");
    });

    it("Should revert if insufficient funds", async function () {
      const insufficientAmount = ethers.utils.parseEther("0.5");

      await expect(
        marketplaceFacet
          .connect(buyer)
          .buyNFT(mockERC721.address, tokenId, { value: insufficientAmount })
      ).to.be.revertedWith("You didn't send enough ETH");
    });

    it("Should handle fee calculation correctly", async function () {
      // Test with different fee
      await marketplaceFacet.connect(owner).updateMarketplaceFee(500); // 5%

      const newFee = price.mul(500).div(10000);
      const treasuryBalanceBefore = await ethers.provider.getBalance(
        treasuryAddress
      );

      await marketplaceFacet
        .connect(buyer)
        .buyNFT(mockERC721.address, tokenId, { value: price });

      const treasuryBalanceAfter = await ethers.provider.getBalance(
        treasuryAddress
      );
      expect(treasuryBalanceAfter.sub(treasuryBalanceBefore)).to.equal(newFee);
    });

    it("Should prevent reentrancy attacks", async function () {
      // Deploy a malicious contract that tries to re-enter buyNFT
      const MaliciousBuyer = await ethers.getContractFactory("MaliciousBuyer");
      const maliciousBuyer = await MaliciousBuyer.deploy(diamondAddress);

      // Fund malicious buyer
      await owner.sendTransaction({ to: maliciousBuyer.address, value: price });

      // List NFT
      await marketplaceFacet
        .connect(seller)
        .listNFT(mockERC721.address, tokenId, price);

      // Attempt reentrant buy should fail
      await expect(
        maliciousBuyer.attack(mockERC721.address, tokenId, { value: price })
      ).to.be.revertedWith("ReentrancyGuard: reentrant call");
    });
  });

  // === Cancel Listing
  describe("cancelListing", function () {
    beforeEach(async function () {
      // === List the NFT
      await marketplaceFacet
        .connect(seller)
        .listNFT(mockERC721.address, tokenId, price);
    });

    it("Should cancel listing successfully", async function () {
      await expect(
        marketplaceFacet
          .connect(seller)
          .cancelListing(mockERC721.address, tokenId)
      )
        .to.emit(marketplaceFacet, "ListingCancelled")
        .withArgs(seller.address, mockERC721.address, tokenId);

      const listing = await marketplaceFacet.listings(
        mockERC721.address,
        tokenId
      );
      expect(listing.isActive).to.be.false;
    });

    it("Should revert if caller is not the seller", async function () {
      await expect(
        marketplaceFacet
          .connect(buyer)
          .cancelListing(mockERC721.address, tokenId)
      ).to.be.revertedWith("Only the seller can cancel");
    });

    it("Should revert if NFT is not listed", async function () {
      // Cancel first
      await marketplaceFacet
        .connect(seller)
        .cancelListing(mockERC721.address, tokenId);

      // Try to cancel again
      await expect(
        marketplaceFacet
          .connect(seller)
          .cancelListing(mockERC721.address, tokenId)
      ).to.be.revertedWith("Not listed");
    });
  });

  // === Update Marketplace
  describe("updateMarketplaceFee", function () {
    it("Should update fee successfully by owner", async function () {
      const newFee = 300;

      await expect(marketplaceFacet.connect(owner).updateMarketplaceFee(newFee))
        .to.emit(marketplaceFacet, "MarketplaceFeeUpdated")
        .withArgs(newFee);

      expect(await marketplaceFacet.marketplaceFeeBps()).to.equal(newFee);
    });

    it("Should revert if caller is not owner", async function () {
      await expect(
        marketplaceFacet.connect(seller).updateMarketplaceFee(300)
      ).to.be.reverted;
    });

    it("Should revert if fee is over 100%", async function () {
      await expect(
        marketplaceFacet.connect(owner).updateMarketplaceFee(10001)
      ).to.be.revertedWith("Fee cannot be more than 100%");
    });

    it("Should allow fee of 100%", async function () {
      await marketplaceFacet.connect(owner).updateMarketplaceFee(10000);
      expect(await marketplaceFacet.marketplaceFeeBps()).to.equal(10000);
    });
  });

  // === View Functions
  describe("View Functions", function () {
    beforeEach(async function () {
      // === List the NFT
      await marketplaceFacet
        .connect(seller)
        .listNFT(mockERC721.address, tokenId, price);
    });

    it("getListingDetails should return correct details", async function () {
      const [sellerAddr, listingPrice, isActive] =
        await marketplaceFacet.getListingDetails(mockERC721.address, tokenId);

      expect(sellerAddr).to.equal(seller.address);
      expect(listingPrice).to.equal(price);
      expect(isActive).to.be.true;
    });

    it("getMarketplaceFee should return fee in bps", async function () {
      expect(await marketplaceFacet.getMarketplaceFee()).to.equal(
        initialFeeBps
      );
    });

    it("getMarketplaceFeeInPercent should return fee in percent", async function () {
      expect(await marketplaceFacet.getMarketplaceFeeInPercent()).to.equal(2); // 250 bps = 2%
    });

    it("getTreasuryBalance should return treasury balance", async function () {
      // === Send some ETH to treasury for testing
      await owner.sendTransaction({
        to: treasuryAddress,
        value: ethers.utils.parseEther("1"),
      });

      expect(await marketplaceFacet.getTreasuryBalance()).to.equal(
        ethers.utils.parseEther("1")
      );
    });
  });

  // === Integrations Tests
  describe("Integration Tests", function () {
    it("Complete flow: list, buy, and verify state changes", async function () {
      // === List NFT
      await marketplaceFacet
        .connect(seller)
        .listNFT(mockERC721.address, tokenId, price);

      // === Verify listing
      let listing = await marketplaceFacet.listings(mockERC721.address, tokenId);
      expect(listing.isActive).to.be.true;
      expect(await mockERC721.ownerOf(tokenId)).to.equal(seller.address);

      // === Buy NFT
      await marketplaceFacet
        .connect(buyer)
        .buyNFT(mockERC721.address, tokenId, { value: price });

      // === Verify purchase
      expect(await mockERC721.ownerOf(tokenId)).to.equal(buyer.address);
      listing = await marketplaceFacet.listings(mockERC721.address, tokenId);
      expect(listing.isActive).to.be.false;
    });

    it("Should handle multiple listings", async function () {
      // === Mint another NFT
      const tokenId2 = 2;
      await mockERC721.mint(seller.address, tokenId2);
      await mockERC721.connect(seller).approve(diamondAddress, tokenId2);

      const price2 = ethers.utils.parseEther("2");

      // === List both NFTs
      await marketplaceFacet
        .connect(seller)
        .listNFT(mockERC721.address, tokenId, price);
      await marketplaceFacet
        .connect(seller)
        .listNFT(mockERC721.address, tokenId2, price2);

      // === Buy first NFT
      await marketplaceFacet
        .connect(buyer)
        .buyNFT(mockERC721.address, tokenId, { value: price });

      // === Check that second listing is still active
      const listing2 = await marketplaceFacet.listings(
        mockERC721.address,
        tokenId2
      );
      expect(listing2.isActive).to.be.true;
    });
  });
});
