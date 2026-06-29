# NFT Marketplace

## Overview

This is a simple, non-custodial NFT marketplace smart contract where users can list their NFTs for sale, buy NFTs, and cancel listings. The marketplace operates with a fee (in basis points), and the fees are sent to a treasury address.

## Features

+ List NFTs: Users can list their NFTs for sale by specifying the price.

+ Buy NFTs: Buyers can purchase NFTs listed on the marketplace. The seller receives the price minus the marketplace fee, which is sent to the treasury.

+ Cancel Listings: Sellers can cancel their own listings at any time before the NFT is sold.

+ Fee Management: The owner can update the marketplace fee (in basis points).

+ Non-Custodial: NFTs stay in the seller's wallet, and the marketplace only facilitates the transfer when a purchase occurs.

## Contract Structure

The contract inherits from `Ownable` (for owner permissions) and `ReentrancyGuard` (to prevent reentrancy attacks).

## Key Variables

+ **marketplaceFeeBps:** The marketplace fee in basis points (bps). 1 bps = 0.01%. Maximum allowed is 10,000 bps (100%).

+ treasury: The address that receives the marketplace fees.

## Key Functions

+ listNFT(address _nftAddress, uint256 _tokenId, uint256 _price): List an NFT for sale. Requires approval from the user for the marketplace contract to transfer the NFT.

+ buyNFT(address _nftAddress, uint256 _tokenId): Purchase a listed NFT. The buyer sends ETH, and the NFT is transferred to the buyer. The seller receives the price minus the marketplace fee.

+ cancelListing(address _nftAddress, uint256 _tokenId): Cancel the seller's listing. The NFT remains in the seller's wallet.

+ updateMarketplaceFee(uint256 _newFeeBps): Owner-only function to update the marketplace fee in basis points.

+ getListingDetails(address _nftAddress, uint256 _tokenId): View function to check the details of a listed NFT (seller, price, and active status).

+ getMarketplaceFee(): View function to get the current marketplace fee in basis points.

+ getMarketplaceFeeInPercent(): View function to get the current marketplace fee in percentage.

+ getTreasuryBalance(): View function to get the current balance of the treasury.

## Error Handling

+ The contract performs checks to ensure that only the owner can update the fee, that NFTs are owned by the seller before listing, and that the marketplace is approved to transfer NFTs.

+ If the buyer sends too little ETH, the transaction fails.

+ If the seller has cancelled the listing, the transaction fails.

+ Refunds are provided if the buyer overpays.

## Installation

### Dependencies

`@openzeppelin/contracts`: The contract depends on the OpenZeppelin contracts library, specifically `IERC721` for interacting with NFTs.

To install the dependencies:

```bash
pnpm install
```

### Hardhat Setup

To test and deploy the contract, you can use Hardhat:

1. Install the necessary dependencies:

```bash
pnpm install 
```

2. Compile the contract:

```bash
pnpm hardhat compile
```

3. Deploy the contract:

```bash
pnpm hardhat run scripts/deploy.js --network <network>
```

## Error with `@openzeppelin/contracts`

The error message you're seeing: `Source "@openzeppelin/contracts/token/ERC721/IERC721.sol" not found: File not found` typically means that your project cannot locate the `@openzeppelin/contracts` package.

### Solutions:

1. **Check Package Installation**: Ensure that the @openzeppelin/contracts package is correctly installed in the node_modules directory.

+ If you're using `pnpm`, run:

```bash
pnpm install 
```

+ If you're using `npm`, run:

```bash
npm install @openzeppelin/contracts
```

+ If you're using `yarn`, run:

```bash
yarn add @openzeppelin/contracts
```

2. **Correct File Path**: Verify the file path in the import statement:

```solidity
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
```

3. **Version Compatibility**: Ensure that the version of `@openzeppelin/contracts` in your `package.json` matches the one you are using. If the issue persists, try uninstalling and reinstalling the package:

```
pnpm remove @openzeppelin/contracts
pnpm add @openzeppelin/contracts
```

If the issue continues, it could be due to misconfiguration in the project or a specific issue with your package manager's cache.

## License

MIT License

## Author

[Olorunshogo Moses BAMTEFA](https://github.com/Olorunshogo)




