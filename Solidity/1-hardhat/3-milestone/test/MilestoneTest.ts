import { expect } from 'chai';
import { network } from 'hardhat';

const { ethers, networkHelpers } = await network.connect();

describe('MilestoneFactory Contract', function () {
  let factory: any;
  let milestone: any;

  let client: any;
  let freelancer: any;
  let other: any;

  const totalMilestones = 3;
  const milestoneAmount = ethers.parseEther('1');
  const approvalTimeout = 1000;

  const totalFunding = milestoneAmount * BigInt(totalMilestones);

  beforeEach(async () => {
    [client, freelancer, other] = await ethers.getSigners();

    factory = await ethers.deployContract('MilestoneFactory');
    await factory.waitForDeployment();
  });

  describe('createEscrow', () => {
    it('Should create milestone escrow and emit EscrowCreated', async () => {
      await expect(
        factory
          .connect(client)
          .createEscrow(
            freelancer.address,
            totalMilestones,
            milestoneAmount,
            approvalTimeout,
            { value: totalFunding }
          )
      ).to.emit(factory, 'EscrowCreated');

      expect(await factory.escrowCount()).to.equal(1);
    });

    it('Should store escrow address in mapping', async () => {
      await factory
        .connect(client)
        .createEscrow(
          freelancer.address,
          totalMilestones,
          milestoneAmount,
          approvalTimeout,
          { value: totalFunding }
        );

      const escrowAddress = await factory.escrows(0);
      expect(escrowAddress).to.properAddress;
    });

    it('Should revert if funding is incorrect', async () => {
      await expect(
        factory.connect(client).createEscrow(
          freelancer.address,
          totalMilestones,
          milestoneAmount,
          approvalTimeout,
          { value: ethers.parseEther('1') } // incorrect funding
        )
      ).to.be.revertedWith('Incorrect funding');
    });
  });

  describe('Milestone Integration', () => {
    beforeEach(async () => {
      await factory
        .connect(client)
        .createEscrow(
          freelancer.address,
          totalMilestones,
          milestoneAmount,
          approvalTimeout,
          { value: totalFunding }
        );

      const escrowAddress = await factory.escrows(0);

      milestone = await ethers.getContractAt('Milestone', escrowAddress);
    });

    it('Should initialize milestone correctly', async () => {
      expect(await milestone.client()).to.equal(client.address);
      expect(await milestone.freelancer()).to.equal(freelancer.address);
      expect(await milestone.totalMilestones()).to.equal(totalMilestones);
      expect(await milestone.milestoneAmount()).to.equal(milestoneAmount);
      expect(await milestone.status()).to.equal(0); // ACTIVE
    });

    it('Freelancer can mark milestone completed', async () => {
      await milestone.connect(freelancer).markMilestoneCompleted();
      expect(await milestone.completedMilestones()).to.equal(1);
    });

    it('Should revert if non-freelancer marks milestone', async () => {
      await expect(
        milestone.connect(other).markMilestoneCompleted()
      ).to.be.revertedWith('Only freelancer');
    });

    it('Client can approve milestone and release payment', async () => {
      await milestone.connect(freelancer).markMilestoneCompleted();

      const balanceBefore = await ethers.provider.getBalance(
        freelancer.address
      );

      await milestone.connect(client).approveMilestone();

      const balanceAfter = await ethers.provider.getBalance(
        freelancer.address
      );

      expect(balanceAfter - balanceBefore).to.equal(milestoneAmount);
      expect(await milestone.releasedMilestones()).to.equal(1);
    });

    it('Should revert if non-client tries to approve', async () => {
      await milestone.connect(freelancer).markMilestoneCompleted();

      await expect(
        milestone.connect(other).approveMilestone()
      ).to.be.revertedWith('Only client');
    });

    it('Should not release payment if no completed milestone', async () => {
      await expect(
        milestone.connect(client).approveMilestone()
      ).to.be.revertedWith('Nothing to release');
    });

    it('Freelancer can claim timeout payment', async () => {
      await milestone.connect(freelancer).markMilestoneCompleted();

      await networkHelpers.time.increase(approvalTimeout + 1);

      const balanceBefore = await ethers.provider.getBalance(
        freelancer.address
      );

      await milestone.connect(freelancer).claimTimeoutPayment();

      const balanceAfter = await ethers.provider.getBalance(
        freelancer.address
      );

      expect(await milestone.releasedMilestones()).to.equal(1);
      expect(balanceAfter - balanceBefore).to.equal(milestoneAmount);
    });

    it('Should revert timeout claim if timeout not reached', async () => {
      await milestone.connect(freelancer).markMilestoneCompleted();

      await expect(
        milestone.connect(freelancer).claimTimeoutPayment()
      ).to.be.revertedWith('Timeout not reached');
    });

    it('Should complete contract after all milestones paid', async () => {
      for (let i = 0; i < totalMilestones; i++) {
        await milestone.connect(freelancer).markMilestoneCompleted();
        await milestone.connect(client).approveMilestone();
      }

      expect(await milestone.status()).to.equal(1); // COMPLETE
      expect(await milestone.releasedMilestones()).to.equal(totalMilestones);
    });

    it('Should revert if marking milestone after completion', async () => {
      for (let i = 0; i < totalMilestones; i++) {
        await milestone.connect(freelancer).markMilestoneCompleted();
        await milestone.connect(client).approveMilestone();
      }

      await expect(
        milestone.connect(freelancer).markMilestoneCompleted()
      ).to.be.revertedWith('Not active');
    });
  });
});
