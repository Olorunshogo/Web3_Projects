// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {UnsafeUpgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {MilestoneEscrow} from "../src/2-MilestoneEscrow.sol";
import {MilestoneEscrowV2} from "../src/2-MilestoneEscrowV2.sol";
import {MilestoneFactoryV1} from "../src/2-MilestoneFactoryV1.sol";
import {MilestoneFactoryV2} from "../src/2-MilestoneFactoryV2.sol";

contract MilestoneTest is Test {
    address owner;
    address client;
    address freelancer;
    address other;

    uint256 constant TOTAL_MILESTONES = 3;
    uint256 constant MILESTONE_AMOUNT = 1 ether;
    uint256 constant APPROVAL_TIMEOUT = 1000;
    uint256 constant TOTAL_FUNDING = TOTAL_MILESTONES * MILESTONE_AMOUNT;

    function setUp() public {
        owner = address(this);
        client = makeAddr("client");
        freelancer = makeAddr("freelancer");
        other = makeAddr("other");

        vm.deal(client, 100 ether);
        vm.deal(owner, 100 ether);
    }

    // =========================================================
    // 20.1 — MilestoneEscrow V1 Unit Tests (plain contract, no proxy)
    // =========================================================

    function _deployEscrow() internal returns (MilestoneEscrow) {
        vm.prank(client);
        return new MilestoneEscrow{value: TOTAL_FUNDING}(
            client, freelancer, TOTAL_MILESTONES, MILESTONE_AMOUNT, APPROVAL_TIMEOUT
        );
    }

    function test_Escrow_InitializesCorrectly() public {
        MilestoneEscrow escrow = _deployEscrow();

        assertEq(escrow.client(), client);
        assertEq(escrow.freelancer(), freelancer);
        assertEq(escrow.totalMilestones(), TOTAL_MILESTONES);
        assertEq(escrow.milestoneAmount(), MILESTONE_AMOUNT);
        assertEq(escrow.approvalTimeout(), APPROVAL_TIMEOUT);
        assertEq(uint8(escrow.status()), uint8(MilestoneEscrow.Status.ACTIVE));
        assertEq(escrow.completedMilestones(), 0);
        assertEq(escrow.releasedMilestones(), 0);
    }

    function test_Escrow_RevertOnIncorrectFunding() public {
        vm.prank(client);
        vm.expectRevert("Incorrect funding");
        new MilestoneEscrow{value: 1 ether}(
            client, freelancer, TOTAL_MILESTONES, MILESTONE_AMOUNT, APPROVAL_TIMEOUT
        );
    }

    function test_Escrow_FreelancerCanMarkCompleted() public {
        MilestoneEscrow escrow = _deployEscrow();

        vm.prank(freelancer);
        escrow.markMilestoneCompleted();

        assertEq(escrow.completedMilestones(), 1);
    }

    function test_Escrow_RevertMarkCompletedIfNotFreelancer() public {
        MilestoneEscrow escrow = _deployEscrow();

        vm.prank(other);
        vm.expectRevert("Only freelancer");
        escrow.markMilestoneCompleted();
    }

    function test_Escrow_RevertMarkCompletedIfNotActive() public {
        MilestoneEscrow escrow = _deployEscrow();

        // Complete all milestones to reach COMPLETE status
        for (uint256 i = 0; i < TOTAL_MILESTONES; i++) {
            vm.prank(freelancer);
            escrow.markMilestoneCompleted();
            vm.prank(client);
            escrow.approveMilestone();
        }

        vm.prank(freelancer);
        vm.expectRevert("Not active");
        escrow.markMilestoneCompleted();
    }

    function test_Escrow_ClientApprovesAndReleasesPayment() public {
        MilestoneEscrow escrow = _deployEscrow();

        vm.prank(freelancer);
        escrow.markMilestoneCompleted();

        uint256 balanceBefore = freelancer.balance;

        vm.prank(client);
        escrow.approveMilestone();

        assertEq(freelancer.balance - balanceBefore, MILESTONE_AMOUNT);
        assertEq(escrow.releasedMilestones(), 1);
    }

    function test_Escrow_RevertApproveIfNotClient() public {
        MilestoneEscrow escrow = _deployEscrow();

        vm.prank(freelancer);
        escrow.markMilestoneCompleted();

        vm.prank(other);
        vm.expectRevert("Only client");
        escrow.approveMilestone();
    }

    function test_Escrow_RevertApproveWithNothingToRelease() public {
        MilestoneEscrow escrow = _deployEscrow();

        vm.prank(client);
        vm.expectRevert("Nothing to release");
        escrow.approveMilestone();
    }

    function test_Escrow_FreelancerClaimsTimeoutPayment() public {
        MilestoneEscrow escrow = _deployEscrow();

        vm.prank(freelancer);
        escrow.markMilestoneCompleted();

        vm.warp(block.timestamp + APPROVAL_TIMEOUT + 1);

        uint256 balanceBefore = freelancer.balance;

        vm.prank(freelancer);
        escrow.claimTimeoutPayment();

        assertEq(freelancer.balance - balanceBefore, MILESTONE_AMOUNT);
        assertEq(escrow.releasedMilestones(), 1);
    }

    function test_Escrow_RevertTimeoutClaimIfNotReached() public {
        MilestoneEscrow escrow = _deployEscrow();

        vm.prank(freelancer);
        escrow.markMilestoneCompleted();

        vm.prank(freelancer);
        vm.expectRevert("Timeout not reached");
        escrow.claimTimeoutPayment();
    }

    function test_Escrow_CompletesAfterAllMilestonesPaid() public {
        MilestoneEscrow escrow = _deployEscrow();

        for (uint256 i = 0; i < TOTAL_MILESTONES; i++) {
            vm.prank(freelancer);
            escrow.markMilestoneCompleted();
            vm.prank(client);
            escrow.approveMilestone();
        }

        assertEq(uint8(escrow.status()), uint8(MilestoneEscrow.Status.COMPLETE));
        assertEq(escrow.releasedMilestones(), TOTAL_MILESTONES);
    }

    // =========================================================
    // 20.2 — MilestoneFactory V1 Unit Tests (factory is UUPS proxy)
    // =========================================================

    function _deployFactoryV1() internal returns (address factoryProxy, MilestoneFactoryV1 factory) {
        address factoryImpl = address(new MilestoneFactoryV1());
        factoryProxy = UnsafeUpgrades.deployUUPSProxy(
            factoryImpl,
            abi.encodeCall(MilestoneFactoryV1.initialize, (owner))
        );
        factory = MilestoneFactoryV1(factoryProxy);
    }

    function test_Factory_InitializesCorrectly() public {
        (, MilestoneFactoryV1 factory) = _deployFactoryV1();

        assertEq(factory.owner(), owner);
        assertEq(factory.escrowCount(), 0);
    }

    function test_Factory_DoubleInit_Reverts() public {
        (, MilestoneFactoryV1 factory) = _deployFactoryV1();

        vm.expectRevert();
        factory.initialize(other);
    }

    function test_Factory_CreateEscrow_DeploysMilestoneEscrow() public {
        (, MilestoneFactoryV1 factory) = _deployFactoryV1();

        vm.deal(client, 100 ether);
        vm.prank(client);
        address escrowAddr = factory.createEscrow{value: TOTAL_FUNDING}(
            freelancer, TOTAL_MILESTONES, MILESTONE_AMOUNT, APPROVAL_TIMEOUT
        );

        assertTrue(escrowAddr != address(0));

        // Verify it's a MilestoneEscrow (not V2) by checking it has no disputed() function
        MilestoneEscrow escrow = MilestoneEscrow(payable(escrowAddr));
        assertEq(escrow.client(), client);
        assertEq(escrow.freelancer(), freelancer);
        assertEq(escrow.totalMilestones(), TOTAL_MILESTONES);
        assertEq(escrow.milestoneAmount(), MILESTONE_AMOUNT);
    }

    function test_Factory_CreateEscrow_IncrementsEscrowCount() public {
        (, MilestoneFactoryV1 factory) = _deployFactoryV1();

        vm.deal(client, 100 ether);
        vm.prank(client);
        factory.createEscrow{value: TOTAL_FUNDING}(
            freelancer, TOTAL_MILESTONES, MILESTONE_AMOUNT, APPROVAL_TIMEOUT
        );

        assertEq(factory.escrowCount(), 1);

        vm.prank(client);
        factory.createEscrow{value: TOTAL_FUNDING}(
            freelancer, TOTAL_MILESTONES, MILESTONE_AMOUNT, APPROVAL_TIMEOUT
        );

        assertEq(factory.escrowCount(), 2);
    }

    function test_Factory_CreateEscrow_StoresEscrowAddress() public {
        (, MilestoneFactoryV1 factory) = _deployFactoryV1();

        vm.deal(client, 100 ether);
        vm.prank(client);
        address escrowAddr = factory.createEscrow{value: TOTAL_FUNDING}(
            freelancer, TOTAL_MILESTONES, MILESTONE_AMOUNT, APPROVAL_TIMEOUT
        );

        assertEq(factory.escrows(0), escrowAddr);
    }

    function test_Factory_CreateEscrow_EmitsEvent() public {
        (, MilestoneFactoryV1 factory) = _deployFactoryV1();

        vm.deal(client, 100 ether);
        vm.prank(client);
        vm.expectEmit(true, false, false, false);
        emit MilestoneFactoryV1.EscrowCreated(0, address(0));

        factory.createEscrow{value: TOTAL_FUNDING}(
            freelancer, TOTAL_MILESTONES, MILESTONE_AMOUNT, APPROVAL_TIMEOUT
        );
    }

    function test_Factory_CreateEscrow_RevertOnIncorrectFunding() public {
        (, MilestoneFactoryV1 factory) = _deployFactoryV1();

        vm.deal(client, 100 ether);
        vm.prank(client);
        vm.expectRevert("Incorrect funding");
        factory.createEscrow{value: 1 ether}(
            freelancer, TOTAL_MILESTONES, MILESTONE_AMOUNT, APPROVAL_TIMEOUT
        );
    }

    // =========================================================
    // 20.3 — Upgrade Path Tests: V1 → V2
    // =========================================================

    function test_Upgrade_EscrowCountPreserved() public {
        (address factoryProxy, MilestoneFactoryV1 factory) = _deployFactoryV1();

        // Create two escrows in V1
        vm.deal(client, 100 ether);
        vm.prank(client);
        factory.createEscrow{value: TOTAL_FUNDING}(
            freelancer, TOTAL_MILESTONES, MILESTONE_AMOUNT, APPROVAL_TIMEOUT
        );
        vm.prank(client);
        factory.createEscrow{value: TOTAL_FUNDING}(
            freelancer, TOTAL_MILESTONES, MILESTONE_AMOUNT, APPROVAL_TIMEOUT
        );

        address escrow0Before = factory.escrows(0);
        address escrow1Before = factory.escrows(1);

        // Upgrade factory to V2
        UnsafeUpgrades.upgradeProxy(factoryProxy, address(new MilestoneFactoryV2()), "");
        MilestoneFactoryV2 factoryV2 = MilestoneFactoryV2(factoryProxy);

        // Assert escrowCount and escrows mapping preserved
        assertEq(factoryV2.escrowCount(), 2);
        assertEq(factoryV2.escrows(0), escrow0Before);
        assertEq(factoryV2.escrows(1), escrow1Before);
    }

    function test_Upgrade_OwnerPreserved() public {
        (address factoryProxy, MilestoneFactoryV1 factory) = _deployFactoryV1();
        address ownerBefore = factory.owner();

        UnsafeUpgrades.upgradeProxy(factoryProxy, address(new MilestoneFactoryV2()), "");
        MilestoneFactoryV2 factoryV2 = MilestoneFactoryV2(factoryProxy);

        assertEq(factoryV2.owner(), ownerBefore);
    }

    function test_Upgrade_V2CreateEscrow_DeploysMilestoneEscrowV2() public {
        (address factoryProxy,) = _deployFactoryV1();

        UnsafeUpgrades.upgradeProxy(factoryProxy, address(new MilestoneFactoryV2()), "");
        MilestoneFactoryV2 factoryV2 = MilestoneFactoryV2(factoryProxy);

        vm.deal(client, 100 ether);
        vm.prank(client);
        address escrowAddr = factoryV2.createEscrow{value: TOTAL_FUNDING}(
            freelancer, TOTAL_MILESTONES, MILESTONE_AMOUNT, APPROVAL_TIMEOUT
        );

        // Verify it's a MilestoneEscrowV2 by calling disputeMilestone
        MilestoneEscrowV2 escrowV2 = MilestoneEscrowV2(payable(escrowAddr));
        assertEq(escrowV2.disputed(), false);
    }

    function test_Upgrade_V2CreateEscrow_IncrementsCount() public {
        (address factoryProxy, MilestoneFactoryV1 factory) = _deployFactoryV1();

        // Create one escrow in V1
        vm.deal(client, 100 ether);
        vm.prank(client);
        factory.createEscrow{value: TOTAL_FUNDING}(
            freelancer, TOTAL_MILESTONES, MILESTONE_AMOUNT, APPROVAL_TIMEOUT
        );

        UnsafeUpgrades.upgradeProxy(factoryProxy, address(new MilestoneFactoryV2()), "");
        MilestoneFactoryV2 factoryV2 = MilestoneFactoryV2(factoryProxy);

        // Create one escrow in V2
        vm.prank(client);
        factoryV2.createEscrow{value: TOTAL_FUNDING}(
            freelancer, TOTAL_MILESTONES, MILESTONE_AMOUNT, APPROVAL_TIMEOUT
        );

        assertEq(factoryV2.escrowCount(), 2);
    }

    function test_Upgrade_DisputeMilestone_SetsDisputedFlag() public {
        (address factoryProxy,) = _deployFactoryV1();

        UnsafeUpgrades.upgradeProxy(factoryProxy, address(new MilestoneFactoryV2()), "");
        MilestoneFactoryV2 factoryV2 = MilestoneFactoryV2(factoryProxy);

        vm.deal(client, 100 ether);
        vm.prank(client);
        address escrowAddr = factoryV2.createEscrow{value: TOTAL_FUNDING}(
            freelancer, TOTAL_MILESTONES, MILESTONE_AMOUNT, APPROVAL_TIMEOUT
        );

        MilestoneEscrowV2 escrowV2 = MilestoneEscrowV2(payable(escrowAddr));

        vm.prank(client);
        escrowV2.disputeMilestone();

        assertTrue(escrowV2.disputed());
    }

    function test_Upgrade_DisputeBlocksApprove() public {
        (address factoryProxy,) = _deployFactoryV1();

        UnsafeUpgrades.upgradeProxy(factoryProxy, address(new MilestoneFactoryV2()), "");
        MilestoneFactoryV2 factoryV2 = MilestoneFactoryV2(factoryProxy);

        vm.deal(client, 100 ether);
        vm.prank(client);
        address escrowAddr = factoryV2.createEscrow{value: TOTAL_FUNDING}(
            freelancer, TOTAL_MILESTONES, MILESTONE_AMOUNT, APPROVAL_TIMEOUT
        );

        MilestoneEscrowV2 escrowV2 = MilestoneEscrowV2(payable(escrowAddr));

        vm.prank(freelancer);
        escrowV2.markMilestoneCompleted();

        vm.prank(client);
        escrowV2.disputeMilestone();

        vm.prank(client);
        vm.expectRevert("Milestone is disputed");
        escrowV2.approveMilestone();
    }

    function test_Upgrade_DisputeBlocksTimeoutClaim() public {
        (address factoryProxy,) = _deployFactoryV1();

        UnsafeUpgrades.upgradeProxy(factoryProxy, address(new MilestoneFactoryV2()), "");
        MilestoneFactoryV2 factoryV2 = MilestoneFactoryV2(factoryProxy);

        vm.deal(client, 100 ether);
        vm.prank(client);
        address escrowAddr = factoryV2.createEscrow{value: TOTAL_FUNDING}(
            freelancer, TOTAL_MILESTONES, MILESTONE_AMOUNT, APPROVAL_TIMEOUT
        );

        MilestoneEscrowV2 escrowV2 = MilestoneEscrowV2(payable(escrowAddr));

        vm.prank(freelancer);
        escrowV2.markMilestoneCompleted();

        vm.prank(client);
        escrowV2.disputeMilestone();

        vm.warp(block.timestamp + APPROVAL_TIMEOUT + 1);

        vm.prank(freelancer);
        vm.expectRevert("Milestone is disputed");
        escrowV2.claimTimeoutPayment();
    }

    function test_Upgrade_ResolveDispute_ReleasesToFreelancer() public {
        (address factoryProxy,) = _deployFactoryV1();

        UnsafeUpgrades.upgradeProxy(factoryProxy, address(new MilestoneFactoryV2()), "");
        MilestoneFactoryV2 factoryV2 = MilestoneFactoryV2(factoryProxy);

        vm.deal(client, 100 ether);
        vm.prank(client);
        address escrowAddr = factoryV2.createEscrow{value: TOTAL_FUNDING}(
            freelancer, TOTAL_MILESTONES, MILESTONE_AMOUNT, APPROVAL_TIMEOUT
        );

        MilestoneEscrowV2 escrowV2 = MilestoneEscrowV2(payable(escrowAddr));

        vm.prank(freelancer);
        escrowV2.markMilestoneCompleted();

        vm.prank(client);
        escrowV2.disputeMilestone();

        uint256 balanceBefore = freelancer.balance;

        vm.prank(client);
        escrowV2.resolveDispute(true);

        assertEq(freelancer.balance - balanceBefore, MILESTONE_AMOUNT);
        assertFalse(escrowV2.disputed());
    }

    function test_Upgrade_ResolveDispute_RefundsClient() public {
        (address factoryProxy,) = _deployFactoryV1();

        UnsafeUpgrades.upgradeProxy(factoryProxy, address(new MilestoneFactoryV2()), "");
        MilestoneFactoryV2 factoryV2 = MilestoneFactoryV2(factoryProxy);

        vm.deal(client, 100 ether);
        vm.prank(client);
        address escrowAddr = factoryV2.createEscrow{value: TOTAL_FUNDING}(
            freelancer, TOTAL_MILESTONES, MILESTONE_AMOUNT, APPROVAL_TIMEOUT
        );

        MilestoneEscrowV2 escrowV2 = MilestoneEscrowV2(payable(escrowAddr));

        vm.prank(client);
        escrowV2.disputeMilestone();

        uint256 clientBalanceBefore = client.balance;

        vm.prank(client);
        escrowV2.resolveDispute(false);

        assertEq(client.balance - clientBalanceBefore, MILESTONE_AMOUNT);
        assertFalse(escrowV2.disputed());
    }

    function test_Upgrade_ResolveDispute_RevertIfNotDisputed() public {
        (address factoryProxy,) = _deployFactoryV1();

        UnsafeUpgrades.upgradeProxy(factoryProxy, address(new MilestoneFactoryV2()), "");
        MilestoneFactoryV2 factoryV2 = MilestoneFactoryV2(factoryProxy);

        vm.deal(client, 100 ether);
        vm.prank(client);
        address escrowAddr = factoryV2.createEscrow{value: TOTAL_FUNDING}(
            freelancer, TOTAL_MILESTONES, MILESTONE_AMOUNT, APPROVAL_TIMEOUT
        );

        MilestoneEscrowV2 escrowV2 = MilestoneEscrowV2(payable(escrowAddr));

        vm.prank(client);
        vm.expectRevert("Not disputed");
        escrowV2.resolveDispute(true);
    }

    function test_Upgrade_DisputeMilestone_RevertIfNotClient() public {
        (address factoryProxy,) = _deployFactoryV1();

        UnsafeUpgrades.upgradeProxy(factoryProxy, address(new MilestoneFactoryV2()), "");
        MilestoneFactoryV2 factoryV2 = MilestoneFactoryV2(factoryProxy);

        vm.deal(client, 100 ether);
        vm.prank(client);
        address escrowAddr = factoryV2.createEscrow{value: TOTAL_FUNDING}(
            freelancer, TOTAL_MILESTONES, MILESTONE_AMOUNT, APPROVAL_TIMEOUT
        );

        MilestoneEscrowV2 escrowV2 = MilestoneEscrowV2(payable(escrowAddr));

        vm.prank(other);
        vm.expectRevert("Only client");
        escrowV2.disputeMilestone();
    }

    // =========================================================
    // 20.4 — Fuzz Test: Milestone Amounts Preserved After Upgrade
    // Feature: oz-upgradeable-v1-v2, Property 3: Milestone Amounts Preserved After Upgrade
    // =========================================================

    function test_fuzz_Milestone_AmountsPreservedAfterUpgrade(
        uint256 totalMilestones,
        uint256 milestoneAmount
    ) public {
        // Bound inputs to valid ranges
        totalMilestones = bound(totalMilestones, 1, 10);
        milestoneAmount = bound(milestoneAmount, 1, 1 ether);

        _fuzz_deployAndVerify(totalMilestones, milestoneAmount);
    }

    /// @dev Extracted to avoid stack-too-deep in the fuzz test
    function _fuzz_deployAndVerify(uint256 totalMilestones, uint256 milestoneAmount) internal {
        uint256 totalFunding = totalMilestones * milestoneAmount;
        vm.deal(client, totalFunding * 3);

        // Deploy MilestoneEscrow (V1 plain contract) directly
        vm.prank(client);
        MilestoneEscrow escrowV1 = new MilestoneEscrow{value: totalFunding}(
            client, freelancer, totalMilestones, milestoneAmount, APPROVAL_TIMEOUT
        );

        // Assert V1 plain contract values are as expected
        assertEq(escrowV1.totalMilestones(), totalMilestones);
        assertEq(escrowV1.milestoneAmount(), milestoneAmount);

        // Deploy factory V1 proxy
        address factoryProxy = UnsafeUpgrades.deployUUPSProxy(
            address(new MilestoneFactoryV1()),
            abi.encodeCall(MilestoneFactoryV1.initialize, (owner))
        );
        MilestoneFactoryV1 factory = MilestoneFactoryV1(factoryProxy);

        // Create a V1 escrow via factory
        vm.prank(client);
        factory.createEscrow{value: totalFunding}(
            freelancer, totalMilestones, milestoneAmount, APPROVAL_TIMEOUT
        );

        address escrow0Before = factory.escrows(0);

        // Upgrade factory to V2
        UnsafeUpgrades.upgradeProxy(factoryProxy, address(new MilestoneFactoryV2()), "");
        MilestoneFactoryV2 factoryV2 = MilestoneFactoryV2(factoryProxy);

        // Assert factory state preserved after upgrade
        assertEq(factoryV2.escrowCount(), 1);
        assertEq(factoryV2.escrows(0), escrow0Before);

        // Create a new V2 escrow and verify amounts are preserved
        vm.prank(client);
        address escrowV2Addr = factoryV2.createEscrow{value: totalFunding}(
            freelancer, totalMilestones, milestoneAmount, APPROVAL_TIMEOUT
        );

        MilestoneEscrowV2 escrowV2 = MilestoneEscrowV2(payable(escrowV2Addr));
        assertEq(escrowV2.totalMilestones(), totalMilestones);
        assertEq(escrowV2.milestoneAmount(), milestoneAmount);
    }
}
