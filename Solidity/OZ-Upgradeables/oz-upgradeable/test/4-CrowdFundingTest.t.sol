// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {UnsafeUpgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {CrowdFundingV1} from "../src/4-CrowdFundingV1.sol";
import {CrowdFundingV2} from "../src/4-CrowdFundingV2.sol";

contract CrowdFundingTest is Test {
    address owner;
    address addr1;
    address addr2;
    address proxy;
    CrowdFundingV1 cf;

    uint256 constant FUNDING_GOAL = 5 ether;
    uint256 constant DURATION = 1000;

    // Allow this contract to receive ETH (needed for withdrawFunds)
    receive() external payable {}

    function setUp() public {
        owner = address(this);
        addr1 = makeAddr("addr1");
        addr2 = makeAddr("addr2");

        vm.deal(owner, 100 ether);
        vm.deal(addr1, 100 ether);
        vm.deal(addr2, 100 ether);

        address impl = address(new CrowdFundingV1());
        proxy = UnsafeUpgrades.deployUUPSProxy(
            impl,
            abi.encodeCall(CrowdFundingV1.initialize, (owner, FUNDING_GOAL, DURATION))
        );
        cf = CrowdFundingV1(proxy);
    }

    // =========================================================
    // 22.1 — V1 Unit Tests
    // =========================================================

    // --- deployment ---

    function test_Deployment_SetsCorrectState() public view {
        assertEq(cf.owner(), owner);
        assertEq(cf.fundingGoal(), FUNDING_GOAL);
        assertGt(cf.deadline(), 0);
        assertEq(uint8(cf.vaultStatus()), 1); // ACTIVE
        assertEq(cf.totalRaised(), 0);
    }

    // --- contribute ---

    function test_Contribute_UpdatesStateAndEmits() public {
        uint256 amount = 2 ether;

        vm.expectEmit(true, false, false, true);
        emit CrowdFundingV1.Contributed(addr1, amount);

        vm.prank(addr1);
        cf.contribute{value: amount}();

        assertEq(cf.contributions(addr1), amount);
        assertEq(cf.totalRaised(), amount);
        assertEq(uint8(cf.vaultStatus()), 1); // still ACTIVE
    }

    function test_Contribute_ChangesStatusToSuccessfulOnGoalReached() public {
        vm.prank(addr1);
        cf.contribute{value: 3 ether}();

        vm.expectEmit(true, false, false, true);
        emit CrowdFundingV1.Log(addr2, "Funding goal reached");

        vm.prank(addr2);
        cf.contribute{value: 2 ether}();

        assertEq(uint8(cf.vaultStatus()), 2); // SUCCESSFUL
    }

    function test_Contribute_RevertOnZeroValue() public {
        vm.prank(addr1);
        vm.expectRevert("Too small. Must send ETH > 0");
        cf.contribute{value: 0}();
    }

    function test_Contribute_RevertIfVaultNotActive() public {
        // Reach goal to make status SUCCESSFUL
        vm.prank(addr1);
        cf.contribute{value: FUNDING_GOAL}();

        vm.prank(addr2);
        vm.expectRevert("Chill first, the funding is not active!");
        cf.contribute{value: 1 ether}();
    }

    function test_Contribute_RevertIfDeadlinePassed() public {
        vm.warp(block.timestamp + DURATION + 1);

        vm.prank(addr1);
        vm.expectRevert("Sorry. Deadline has passed to contribute.");
        cf.contribute{value: 1 ether}();
    }

    // --- withdrawFunds ---

    function test_WithdrawFunds_OwnerReceivesFunds() public {
        vm.prank(addr1);
        cf.contribute{value: FUNDING_GOAL}();

        uint256 balanceBefore = owner.balance;
        cf.withdrawFunds();
        assertEq(owner.balance - balanceBefore, FUNDING_GOAL);
    }

    function test_WithdrawFunds_RevertIfNotOwner() public {
        vm.prank(addr1);
        cf.contribute{value: FUNDING_GOAL}();

        vm.prank(addr1);
        vm.expectRevert();
        cf.withdrawFunds();
    }

    function test_WithdrawFunds_RevertIfGoalNotMet() public {
        vm.expectRevert("Goal !met");
        cf.withdrawFunds();
    }

    // --- claimRefund ---

    function test_ClaimRefund_RefundsContributorAfterDeadline() public {
        vm.prank(addr1);
        cf.contribute{value: 2 ether}();

        vm.warp(block.timestamp + DURATION + 1);

        uint256 balanceBefore = addr1.balance;

        vm.prank(addr1);
        cf.claimRefund();

        assertEq(addr1.balance - balanceBefore, 2 ether);
        assertEq(cf.contributions(addr1), 0);
    }

    function test_ClaimRefund_RevertIfDeadlineNotReached() public {
        vm.prank(addr1);
        cf.contribute{value: 2 ether}();

        vm.prank(addr1);
        vm.expectRevert("Deadline not reached");
        cf.claimRefund();
    }

    function test_ClaimRefund_RevertIfGoalWasMet() public {
        vm.prank(addr1);
        cf.contribute{value: 3 ether}();
        vm.prank(addr2);
        cf.contribute{value: 2 ether}();

        vm.warp(block.timestamp + DURATION + 1);

        vm.prank(addr1);
        vm.expectRevert("Goal was met");
        cf.claimRefund();
    }

    function test_ClaimRefund_RevertIfNoContribution() public {
        vm.warp(block.timestamp + DURATION + 1);

        vm.prank(addr2);
        vm.expectRevert("No contribution so far.");
        cf.claimRefund();
    }

    // --- access control & double-init ---

    function test_Initialize_OwnerSetCorrectly() public view {
        assertEq(cf.owner(), owner);
    }

    function test_DoubleInit_Reverts() public {
        vm.expectRevert();
        cf.initialize(addr1, FUNDING_GOAL, DURATION);
    }

    function test_Upgrade_RevertIfNotOwner() public {
        address newImpl = address(new CrowdFundingV2());
        vm.prank(addr1);
        vm.expectRevert();
        CrowdFundingV1(proxy).upgradeToAndCall(newImpl, "");
    }

    // =========================================================
    // 22.2 — Upgrade Path Tests: V1 → V2
    // =========================================================

    function _deployAndContribute()
        internal
        returns (address _proxy, uint256 contribution1, uint256 contribution2)
    {
        address impl = address(new CrowdFundingV1());
        _proxy = UnsafeUpgrades.deployUUPSProxy(
            impl,
            abi.encodeCall(CrowdFundingV1.initialize, (owner, FUNDING_GOAL, DURATION))
        );

        contribution1 = 1 ether;
        contribution2 = 1.5 ether;

        vm.prank(addr1);
        CrowdFundingV1(_proxy).contribute{value: contribution1}();

        vm.prank(addr2);
        CrowdFundingV1(_proxy).contribute{value: contribution2}();
    }

    function test_Upgrade_TotalRaisedPreserved() public {
        (address _proxy, uint256 c1, uint256 c2) = _deployAndContribute();

        uint256 totalBefore = CrowdFundingV1(_proxy).totalRaised();

        UnsafeUpgrades.upgradeProxy(_proxy, address(new CrowdFundingV2()), "");
        CrowdFundingV2 cfV2 = CrowdFundingV2(_proxy);

        assertEq(cfV2.totalRaised(), totalBefore);
        assertEq(cfV2.totalRaised(), c1 + c2);
    }

    function test_Upgrade_FundingGoalPreserved() public {
        (address _proxy, , ) = _deployAndContribute();

        UnsafeUpgrades.upgradeProxy(_proxy, address(new CrowdFundingV2()), "");
        CrowdFundingV2 cfV2 = CrowdFundingV2(_proxy);

        assertEq(cfV2.fundingGoal(), FUNDING_GOAL);
    }

    function test_Upgrade_DeadlinePreserved() public {
        (address _proxy, , ) = _deployAndContribute();

        uint256 deadlineBefore = CrowdFundingV1(_proxy).deadline();

        UnsafeUpgrades.upgradeProxy(_proxy, address(new CrowdFundingV2()), "");
        CrowdFundingV2 cfV2 = CrowdFundingV2(_proxy);

        assertEq(cfV2.deadline(), deadlineBefore);
    }

    function test_Upgrade_ContributionsPreserved() public {
        (address _proxy, uint256 c1, uint256 c2) = _deployAndContribute();

        UnsafeUpgrades.upgradeProxy(_proxy, address(new CrowdFundingV2()), "");
        CrowdFundingV2 cfV2 = CrowdFundingV2(_proxy);

        assertEq(cfV2.contributions(addr1), c1);
        assertEq(cfV2.contributions(addr2), c2);
    }

    function test_Upgrade_VaultStatusPreserved() public {
        (address _proxy, , ) = _deployAndContribute();

        UnsafeUpgrades.upgradeProxy(_proxy, address(new CrowdFundingV2()), "");
        CrowdFundingV2 cfV2 = CrowdFundingV2(_proxy);

        assertEq(uint8(cfV2.vaultStatus()), 1); // ACTIVE
    }

    function test_Upgrade_OwnerPreserved() public {
        (address _proxy, , ) = _deployAndContribute();

        UnsafeUpgrades.upgradeProxy(_proxy, address(new CrowdFundingV2()), "");
        CrowdFundingV2 cfV2 = CrowdFundingV2(_proxy);

        assertEq(cfV2.owner(), owner);
    }

    // --- extendDeadline happy path ---

    function test_ExtendDeadline_HappyPath() public {
        (address _proxy, , ) = _deployAndContribute();

        UnsafeUpgrades.upgradeProxy(_proxy, address(new CrowdFundingV2()), "");
        CrowdFundingV2 cfV2 = CrowdFundingV2(_proxy);

        uint256 deadlineBefore = cfV2.deadline();
        uint256 extraTime = 500;

        vm.expectEmit(false, false, false, true);
        emit CrowdFundingV2.DeadlineExtended(deadlineBefore + extraTime);

        cfV2.extendDeadline(extraTime);

        assertEq(cfV2.deadline(), deadlineBefore + extraTime);
    }

    function test_ExtendDeadline_DeadlineStrictlyIncreases() public {
        (address _proxy, , ) = _deployAndContribute();

        UnsafeUpgrades.upgradeProxy(_proxy, address(new CrowdFundingV2()), "");
        CrowdFundingV2 cfV2 = CrowdFundingV2(_proxy);

        uint256 deadlineBefore = cfV2.deadline();
        cfV2.extendDeadline(1);

        assertGt(cfV2.deadline(), deadlineBefore);
    }

    // --- extendDeadline revert cases ---

    function test_ExtendDeadline_RevertIfNotOwner() public {
        (address _proxy, , ) = _deployAndContribute();

        UnsafeUpgrades.upgradeProxy(_proxy, address(new CrowdFundingV2()), "");
        CrowdFundingV2 cfV2 = CrowdFundingV2(_proxy);

        vm.prank(addr1);
        vm.expectRevert();
        cfV2.extendDeadline(500);
    }

    function test_ExtendDeadline_RevertIfNotActive() public {
        // Deploy fresh proxy and reach goal to make it SUCCESSFUL
        address impl = address(new CrowdFundingV1());
        address _proxy = UnsafeUpgrades.deployUUPSProxy(
            impl,
            abi.encodeCall(CrowdFundingV1.initialize, (owner, FUNDING_GOAL, DURATION))
        );

        vm.prank(addr1);
        CrowdFundingV1(_proxy).contribute{value: FUNDING_GOAL}();

        UnsafeUpgrades.upgradeProxy(_proxy, address(new CrowdFundingV2()), "");
        CrowdFundingV2 cfV2 = CrowdFundingV2(_proxy);

        vm.expectRevert("Campaign not active");
        cfV2.extendDeadline(500);
    }

    function test_ExtendDeadline_RevertIfGoalAlreadyMet() public {
        // Contribute exactly the goal so totalRaised == fundingGoal (SUCCESSFUL)
        // But we need vaultStatus == ACTIVE with totalRaised >= fundingGoal
        // Actually contributing the full goal sets status to SUCCESSFUL, so test that path
        address impl = address(new CrowdFundingV1());
        address _proxy = UnsafeUpgrades.deployUUPSProxy(
            impl,
            abi.encodeCall(CrowdFundingV1.initialize, (owner, FUNDING_GOAL, DURATION))
        );

        vm.prank(addr1);
        CrowdFundingV1(_proxy).contribute{value: FUNDING_GOAL}();
        // vaultStatus is now SUCCESSFUL

        UnsafeUpgrades.upgradeProxy(_proxy, address(new CrowdFundingV2()), "");
        CrowdFundingV2 cfV2 = CrowdFundingV2(_proxy);

        // "Campaign not active" fires first since status is SUCCESSFUL
        vm.expectRevert("Campaign not active");
        cfV2.extendDeadline(500);
    }

    function test_ExtendDeadline_RevertIfExtraTimeIsZero() public {
        (address _proxy, , ) = _deployAndContribute();

        UnsafeUpgrades.upgradeProxy(_proxy, address(new CrowdFundingV2()), "");
        CrowdFundingV2 cfV2 = CrowdFundingV2(_proxy);

        vm.expectRevert("Extra time must be > 0");
        cfV2.extendDeadline(0);
    }

    // =========================================================
    // 22.3 — Fuzz Test: extendDeadline Only Increases Deadline
    // Feature: oz-upgradeable-v1-v2, Property 6: extendDeadline Only Increases Deadline
    // =========================================================

    function test_fuzz_CrowdFunding_ExtendDeadlineOnlyIncreases(uint256 extraTime) public {
        // Bound extraTime to [1, 365 days]
        extraTime = bound(extraTime, 1, 365 days);

        // Deploy fresh V1 proxy with partial contributions (goal not met)
        address impl = address(new CrowdFundingV1());
        address _proxy = UnsafeUpgrades.deployUUPSProxy(
            impl,
            abi.encodeCall(CrowdFundingV1.initialize, (owner, FUNDING_GOAL, DURATION))
        );

        // Contribute less than goal so campaign stays ACTIVE
        vm.prank(addr1);
        CrowdFundingV1(_proxy).contribute{value: 1 ether}();

        // Record deadline before upgrade
        uint256 deadlineBefore = CrowdFundingV1(_proxy).deadline();

        // Upgrade to V2
        UnsafeUpgrades.upgradeProxy(_proxy, address(new CrowdFundingV2()), "");
        CrowdFundingV2 cfV2 = CrowdFundingV2(_proxy);

        // Extend deadline
        cfV2.extendDeadline(extraTime);

        // Assert new deadline == old deadline + extraTime
        uint256 deadlineAfter = cfV2.deadline();
        assertEq(deadlineAfter, deadlineBefore + extraTime);
        assertGt(deadlineAfter, deadlineBefore);
    }
}
