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
      const deployedContract: Contract = await deployContract("CounterV2");
      console.log("Deployed contract is: ", deployedContract);

      // Assert that default storage value of x is 0
      expect(await deployedContract.x()).to.eq(0);

    });
  });

  describe("Access Control", () => {
    it("Should revert if non-owner tries to call inc()", async () => {
      const [owner, otherAccount] = await ethers.getSigners();
      const deployedContract = await deployContract("CounterV2");

      await expect(
        deployedContract.connect(otherAccount).inc()
      ).to.be.revertedWith("Not the owner");
    });
  });

  // Transactions should capture state changing variable
  describe("Transactions", () => {
    it("Should increase x value by 1", async () => {
      const deployedContract: Contract = await deployContract("CounterV2");
      // console.log("Deployed contract is: ", deployedContract);

      const count1 = await deployedContract.x();
      console.log("Count 1 is: ", count1);

      await deployedContract.inc();

      const count2 = await deployedContract.x();
      console.log("Count 2 is: ", count2);
      expect(count2).to.eq(count1 + 1n);
    });

    it("Should increase x value when inc() is called multiple times", async () => {
      const deployedContract: Contract = await deployContract("CounterV2");
      // console.log("Deployed contract is: ", deployedContract);

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
      const deployedCounter: Contract = await deployContract("CounterV2");
      await expect(deployedCounter.incBy(0)).to.be.revertedWith("incBy: increment should be positive");
    });

    it("Check if the function increases by its given parameters", async () => {
      const deployedCounter: Contract = await deployContract("CounterV2");

      expect(await deployedCounter.x()).to.eq(0);
      const initialInc = await deployedCounter.x();
      console.log("Initial increment is: ", initialInc)

      await deployedCounter.incBy(2);
      const secondInc = await deployedCounter.x();
      console.log("Secound increment is: ", secondInc);

      await expect(secondInc).to.eq(initialInc + 2n);
    });

    it("Should increase x multiple times", async () => {
      const deployedContract: Contract = await deployContract("CounterV2");
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

  describe("Decrement Functions", () => {

    it("Should revert if dec() is called when x is 0", async () => {
      const deployedContract: Contract = await deployContract("CounterV2");

      expect(await deployedContract.x()).to.eq(0); // x = 0

      await expect(deployedContract.dec())
        .to.be.revertedWith("Counter cannot go below 0."); // Reduce below zero
    });

    it("Should decrease x by 1 when dec() is called", async () => {
      const deployedContract: Contract = await deployContract("CounterV2");

      await deployedContract.incBy(3);

      const beforeDec = await deployedContract.x();
      console.log("Before decrement is: ", beforeDec); // 3n
      await deployedContract.dec();
      const afterDec = await deployedContract.x();
      console.log("After decrement is: ", afterDec); // 2n

      expect(afterDec).to.eq(beforeDec - 1n); // 2n = 3n - 1n
    });

    it("Should revert if decBy() tries to reduce below 0", async () => {
      const deployedContract: Contract = await deployContract("CounterV2");

      await deployedContract.incBy(2); // 2n

      await expect(deployedContract.decBy(3))
        .to.be.revertedWith("Counter cannot go below 0."); // -1
    });

    it("Should revert if decBy() is called with 0", async () => {
      const deployedContract: Contract = await deployContract("CounterV2");

      await expect(deployedContract.decBy(0))
        .to.be.revertedWith("Amount must be greater than 0."); // Decrease by 0
    });

    it("Should decrease x by given amount", async () => {
      const deployedContract: Contract = await deployContract("CounterV2");

      await deployedContract.incBy(5);
      const beforeDec = await deployedContract.x();
      console.log("Before decrement is: ", beforeDec); // 5n

      await deployedContract.decBy(3);
      const afterDec = await deployedContract.x();
      console.log("After decrement is: ", afterDec); // 2n

      expect(afterDec).to.eq(beforeDec - 3n); // 5n - 2n
    });

    it("Should decrease correctly multiple times", async () => {
      const deployedContract: Contract = await deployContract("CounterV2");

      await deployedContract.incBy(10);

      await deployedContract.decBy(4);
      const first = await deployedContract.x();
      console.log("First is: ", first); // 6n
      expect(first).to.eq(6n);

      await deployedContract.decBy(2);
      const second = await deployedContract.x();
      console.log("Second is: ", second); // 4n
      expect(second).to.eq(4n); // 4n = 4n
    });

  });

})

