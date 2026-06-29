# Solidity
Practical Solidity smart contract projects demonstrating real-world Ethereum patterns, built with modern tooling such as Hardhat, Foundry, and EVM testing frameworks.

# Solidity Smart Contract Projects

This repository is a growing collection of production-style Solidity smart contracts focused on real-world Ethereum use cases and best practices.

Each project explores common on-chain patterns such as escrows, crowdfunding, auctions, savings mechanisms, and transactional flows, with an emphasis on correctness, security, and clean architecture. The codebase is structured to mirror real smart contract development workflows rather than isolated examples.

The projects are built and tested using modern Ethereum development frameworks and tooling, including **Hardhat**, **Foundry**, and **Ethers**, with room to evolve as the ecosystem advances.

### What this repository demonstrates
- Strong understanding of **Solidity and the EVM**
- Implementation of **real-world smart contract patterns**
- Use of **modern Ethereum tooling** (Hardhat, Foundry, Ethers)
- Focus on **clean code, modularity, and testability**
- Practical experience with **deployment, compilation, and project structuring**

This repository is intended as both a learning sandbox and a professional portfolio, showcasing hands-on experience with building, testing, and maintaining Ethereum smart contracts.


## Useful commands
git rm --cached **/package-lock.json
git rm --cached $(git ls-files | grep package-lock.json)

rm -rf node_modules
rm -f package-lock.json

rm -rf */node_modules
rm -rf */package-lock.json
rm -rf pnpm-lock.yaml
rm -rf */artifacts
rm -rf */cache

<!-- Run Everything -->
pnpm compile
pnpm clean
pnpm test

<!-- Or single project -->
1. **Todo:** pnpm --filter **todo** **compile**/**clean**/**test**

2. **Escrow:** pnpm --filter **escrow** **compile**/**clean**/**test**

3. **Standard Escrow** pnpm --filter **standard-escrow** **compile**/**clean**/**test**

4. **Transaction Savings:** pnpm --filter **transaction-savings** **compile**/**clean**/**test**

5. **CrowdFunding:** pnpm --filter **crowd-funding** **compile**/**clean**/**test**

6. **Auction:** pnpm --filter **auction** **compile**/**clean**/**test**


pnpm turbo run test --filter=auction

pnpm turbo run compile --filter=escrow

pnpm turbo run test --filter=./6-auction
pnpm turbo run test --filter=@solidity/auction





