/* global ethers */

const { getSelectors, FacetCutAction } = require("./libraries/diamond.cjs");

async function deployDiamond() {
  const accounts = await ethers.getSigners();
  const contractOwner = accounts[0];

  // Deploy DiamondCutFacet
  const DiamondCutFacet = await ethers.getContractFactory("DiamondCutFacet");
  const diamondCutFacet = await DiamondCutFacet.deploy();
  await diamondCutFacet.deployed();

  // Deploy Diamond
  const Diamond = await ethers.getContractFactory("Diamond");
  const diamond = await Diamond.deploy(
    contractOwner.address,
    diamondCutFacet.address,
  );
  await diamond.deployed();

  // Deploy DiamondInit
  const DiamondInit = await ethers.getContractFactory("DiamondInit");
  const diamondInit = await DiamondInit.deploy();
  await diamondInit.deployed();

  // Deploy facets
  const FacetNames = [
    "DiamondLoupeFacet",
    "OwnershipFacet",
    "MarketplaceFacet",
  ];
  const cut = [];
  for (const FacetName of FacetNames) {
    const Facet = await ethers.getContractFactory(FacetName);
    const facet = await Facet.deploy();
    await facet.deployed();
    cut.push({
      facetAddress: facet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facet),
    });
  }

  // Upgrade diamond with facets and call init
  const diamondCut = await ethers.getContractAt("IDiamondCut", diamond.address);

  // Use accounts[3] as treasury (matches test signers: owner, seller, buyer, treasury)
  const treasury = accounts[3];
  const initialFeeBps = 250;

  const functionCall = diamondInit.interface.encodeFunctionData("init", [
    initialFeeBps,
    treasury.address,
  ]);
  const tx = await diamondCut.diamondCut(
    cut,
    diamondInit.address,
    functionCall,
  );
  const receipt = await tx.wait();
  if (!receipt.status) {
    throw Error(`Diamond upgrade failed: ${tx.hash}`);
  }

  return diamond.address;
}

exports.deployDiamond = deployDiamond;
