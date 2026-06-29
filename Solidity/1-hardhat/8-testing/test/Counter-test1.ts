import { expect } from "chai";
import { network } from "hardhat";
import type { Contract } from "ethers";

const { ethers } = await network.connect();

// Deploy util
const deployContract = async (contract: string) => {
  const counter: Contract = await ethers.deployContract(contract);
  return counter;
}

// Describe is what we call a test suite
describe("Counter Contract Suite", async () => {
  describe("Deployment", () => {
    it("Should return default storage value", async () => {
      // Call our deploy util function
      const deployedContract: Contract = await deployContract("CounterV1");
      console.log("Deployed contract is: ", deployedContract);

      // Assert that default storage value of x is 0
      expect(await deployedContract.x()).to.eq(0);

    });
  });

  // Transactions should capture state changing variable
  describe("Transactions", () => {
    it("Should increase x value by 1", async () => {
      const deployedContract: Contract = await deployContract("CounterV1");
      // console.log("Deployed counter is: ", deployedCounter);

      const count1 = await deployedContract.x();
      console.log("Count 1 is: ", count1);

      await deployedContract.inc();

      const count2 = await deployedContract.x();
      console.log("Count 2 is: ", count2);
      expect(count2).to.eq(count1 + 1n);
    });

    it("Should increase x value when inc() is called multiple times", async () => {
      const deployedContract: Contract = await deployContract("CounterV1");
      // console.log("Deployed counter is: ", deployedCounter);

      const count1 = await deployedContract.x();
      console.log("Count 1 is: ", count1);

      const increaseNumber: BigInt = 1n;

      await deployedContract.inc();

      const count2 = await deployedContract.x();
      console.log("Count 2 is: ", count2);
      expect(count2).to.eq(count1 + 1n);

      await deployedContract.inc();

      const count3 = await deployedContract.x();
      expect(count3).to.eq(count2 + increaseNumber);

    });
  });

  describe("Inc by functions", () => {

    it("Revert if anything <= 0 is used in the incBy", async () => {
      const deployedCounter: Contract = await deployContract("CounterV1");
      await expect(deployedCounter.incBy(0)).to.be.revertedWith("incBy: increment should be positive");
    });

    it("Check if the function increases by its given parameters", async () => {
      const deployedCounter: Contract = await deployContract("CounterV1");

      expect(await deployedCounter.x()).to.eq(0);
      const initialInc = await deployedCounter.x();
      console.log("Initial increment is: ", initialInc)

      await deployedCounter.incBy(2);
      const secondInc = await deployedCounter.x();
      console.log("Secound increment is: ", secondInc);

      await expect(secondInc).to.eq(initialInc + 2n);
    });

    it("Should increase x multiple times", async () => {
      const deployedContract: Contract = await deployContract("CounterV1");
      const initialInc = await deployedContract.x();
      console.log();

      await deployedContract.incBy(2);
      const secondInc = await deployedContract.x();
      expect(secondInc).to.eq(initialInc + 2n);

      await deployedContract.incBy(3);
      const thirdInc = await deployedContract.x();
      expect(thirdInc).to.eq(secondInc + 3n);
    });

  });
})

