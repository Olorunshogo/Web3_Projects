import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("ERC721Module", (m) => {
  const name: string = "BOMTOKEN";
  const symbol: string = "BMT";
  const baseURI: string = "/";

  const erc721 = m.contract("ERC721", [name, symbol, baseURI]);

  return {erc721};
});
