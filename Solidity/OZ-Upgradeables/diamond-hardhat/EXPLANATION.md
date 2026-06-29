# NFT Marketplace Diamond Contract Explanation

## Overview
This project is a reference implementation of an upgradeable NFT marketplace built on the EIP-2535 Diamond Standard. The marketplace logic lives in a facet so it can be upgraded or extended without changing the diamond address. The diamond is the only address users interact with, while the facets provide the actual functionality through delegatecall.

If you understand three ideas, the rest of the codebase clicks:
1. The diamond is a router that dispatches calls by function selector.
2. Facets contain the logic, but they run in the diamond's storage context.
3. Storage must be carefully namespaced to avoid collisions across facets.

## Repository Layout
- `contracts/Diamond.sol`
  The diamond contract. It implements the fallback dispatcher and receives all calls.
- `contracts/facets/`
  Individual facet contracts that plug into the diamond.
- `contracts/libraries/`
  Shared libraries that define storage layout and internal helpers.
- `contracts/upgradeInitializers/`
  Initialization logic used at deploy or during upgrades.
- `scripts/`
  Deployment script and selector utilities.
- `test/`
  Hardhat tests for the diamond standard and the marketplace behavior.

## Diamond Architecture (EIP-2535)
### Diamond.sol
`contracts/Diamond.sol` is the entry point for all functionality.
- The constructor sets the diamond owner and performs the initial diamond cut.
- The `fallback()` function looks up a facet by selector and delegates the call.
- The `receive()` function allows the diamond to accept ETH.

Because the fallback uses `delegatecall`, the facet code runs as if it were part of the diamond. That means all storage reads and writes happen in the diamond's storage.

### LibDiamond
`contracts/libraries/LibDiamond.sol` defines the diamond's core storage and upgrade logic.
- `DiamondStorage` tracks selector -> facet mappings, supported interfaces, and contract owner.
- `diamondCut()` applies adds, replaces, and removes of function selectors.
- `initializeDiamondCut()` performs an optional delegatecall to an init contract after a cut.
- `enforceIsContractOwner()` gates owner-only functionality.

This library is the heart of the diamond and is reused by multiple facets.

### DiamondCutFacet
`contracts/facets/DiamondCutFacet.sol` exposes the `diamondCut` function externally.
- The owner calls this to add, replace, or remove functions from the diamond.
- It forwards to `LibDiamond.diamondCut()`.

### DiamondLoupeFacet
`contracts/facets/DiamondLoupeFacet.sol` provides introspection required by EIP-2535.
- `facets()` returns all facet addresses and their selectors.
- `facetFunctionSelectors(address)` lists selectors for a facet.
- `facetAddresses()` returns all facet addresses.
- `facetAddress(bytes4)` returns the facet for a given selector.
- `supportsInterface(bytes4)` provides ERC-165 support.

These functions are meant for off-chain tooling and inspection.

### OwnershipFacet
`contracts/facets/OwnershipFacet.sol` implements ERC-173.
- `owner()` returns the diamond owner.
- `transferOwnership(address)` lets the owner transfer control.

This is a lightweight wrapper around `LibDiamond` ownership functions.

## Marketplace Implementation
### MarketplaceFacet
`contracts/facets/MarketplaceFacet.sol` is the marketplace logic.
- `listNFT(address nft, uint256 tokenId, uint256 price)`
  Requires the caller to own the NFT and approve the marketplace. Creates a listing.
- `buyNFT(address nft, uint256 tokenId)`
  Checks listing, charges buyer, transfers NFT, pays seller and treasury, refunds any overpayment.
- `cancelListing(address nft, uint256 tokenId)`
  Only the seller can cancel an active listing.
- `updateMarketplaceFee(uint256 newFeeBps)`
  Owner-only update of the marketplace fee.
- View helpers for listing data, fee, and treasury balance.

Events are emitted for listings, purchases, cancellations, and fee changes.

### LibMarketplace
`contracts/libraries/LibMarketplace.sol` defines marketplace storage.
- `MarketplaceStorage` holds:
  - `marketplaceFeeBps`
  - `treasury`
  - `listings[nftAddress][tokenId]`
- `marketplaceStorage()` returns a storage pointer to a unique keccak slot.

This is the correct way to store facet-specific state in a diamond.

## Initialization
### DiamondInit
`contracts/upgradeInitializers/DiamondInit.sol` runs once during deployment.
- Registers supported interfaces in `LibDiamond` storage.
- Sets initial marketplace fee and treasury in `LibMarketplace` storage.

This is called during the constructor via the `diamondCut` initializer.

### DiamondMultiInit
`contracts/upgradeInitializers/DiamondMultiInit.sol` allows multiple init calls during upgrades.
- Accepts arrays of addresses and calldata.
- Calls each initializer in order via `LibDiamond.initializeDiamondCut`.

## Mock Contracts
### MockERC721
`contracts/MockERC721.sol` is a basic ERC-721 implementation for testing.
- Minimal ownership, approval, transfer, and mint logic.
- Includes `safeTransferFrom` with receiver checks.

### MaliciousBuyer
`contracts/MaliciousBuyer.sol` simulates a reentrancy attempt in tests.
- Calls `buyNFT` and re-enters from its `receive()` function.

## Deployment Flow
### scripts/deploy.cjs
Deployment does the following:
1. Deploy `DiamondInit`.
2. Deploy each facet and build a facet cut with its selectors.
3. Encode the `DiamondInit.init` call with initial fee and treasury.
4. Deploy `Diamond` with the facet cut and init call.

### scripts/libraries/diamond.cjs
Helper utilities for:
- Getting function selectors from ABIs.
- Adding/removing selectors from arrays.
- Finding facet addresses in loupe responses.

## Tests
### test/NFTMarketplaceDiamond.ts
Comprehensive marketplace tests:
- Listing, buying, cancelling.
- Fee calculations and refund logic.
- Reentrancy protection.
- Integration flows with multiple listings.

### test/diamondTest.js
EIP-2535 standard tests:
- Verifies initial facets and selectors.
- Adds/replaces/removes functions.
- Ensures loupe and diamond cut behave correctly.

### test/cacheBugTest.js
Regression test for selector cache bug.
- Ensures removal from selector slots does not corrupt selector mappings.

## Key Diamond Concepts (Practical Notes)
- Facets do not own storage. All state lives in the diamond.
- Storage collisions are a real risk. Use keccak slots via libraries.
- If you add new facets, keep their storage isolated in their own library.
- When you upgrade, you can run an initializer to set new state.

## Current Known Gaps (Implementation Notes)
These are important to understand how the code currently behaves.
- `MarketplaceFacet` currently declares a direct `MarketplaceStorage ms;` variable. That bypasses `LibMarketplace.marketplaceStorage()` and risks storage collisions in a diamond. This should be refactored to use the keccak slot defined in `LibMarketplace`.
- `MarketplaceFacet` inherits `ReentrancyGuard`, which stores `_status` in diamond storage. This can collide with other storage if not properly namespaced.
- Tests include some mismatches with ethers v5 versus v6 APIs and a treasury address mismatch because the diamond is deployed once but `treasuryAddress` is regenerated in each test setup.

These are fixable and should be addressed before relying on tests or deploying to a live network.

## Summary
This project provides a full diamond-based NFT marketplace with:
- Standards-compliant diamond routing and introspection.
- Modular marketplace functionality via a facet.
- Upgrade and initialization patterns via diamond cut.
- Clear examples of tests and upgrade flows.

If you want to extend the marketplace, add new facets and store their state via dedicated libraries. If you want to make it production-ready, address the storage and test issues called out above, then add access controls and additional safety checks specific to your product needs.
