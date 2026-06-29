import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("ERC20Module", (m) => {
  const initialSupply = 2000000000n * 10n ** 6n;
  const erc20 = m.contract("ERC20", ["LONER", "BOM", 6, initialSupply]);

  return {erc20};
});
