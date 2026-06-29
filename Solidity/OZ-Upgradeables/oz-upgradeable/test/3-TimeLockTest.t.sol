// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {UnsafeUpgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {TimeLockV1} from "../src/3-TimeLockV1.sol";
import {TimeLockV2} from "../src/3-TimeLockV2.sol";

contract TimeLockTest is Test {
    address owner;
    address addr1;
    address proxy;
    TimeLockV1 vault;

    uint256 constant LOCK_DURATION = 1000;
    uint256 constant ONE_ETH = 1 ether;

    receive() external payable {}

    function setUp() public {
        owner = address(this);
        addr1 = makeAddr("addr1");

        vm.deal(owner, 100 ether);
        vm.deal(addr1, 100 ether);

        address impl = address(new TimeLockV1());
        proxy = UnsafeUpgrades.deployUUPSProxy(
            impl,
            abi.encodeCall(TimeLockV1.initialize, (owner))
        );
        vault = TimeLockV1(proxy);
    }

    // =========================================================
    // 21.1 — V1 Unit Tests
    // =========================================================

    // --- deposit ---

    function test_Deposit_CreatesVaultAndEmits() public {
        uint256 unlockTime = block.timestamp + LOCK_DURATION;

        vm.expectEmit(true, false, false, true);
        emit TimeLockV1.Deposited(owner, 0, ONE_ETH, unlockTime);

        uint256 vaultId = vault.deposit{value: ONE_ETH}(unlockTime);
        assertEq(vaultId, 0);
    }

    function test_Deposit_RevertOnZeroValue() public {
        vm.expectRevert("Deposit must be greater than zero");
        vault.deposit{value: 0}(block.timestamp + LOCK_DURATION);
    }

    function test_Deposit_RevertIfUnlockTimeInPast() public {
        vm.expectRevert("Unlock time must be in the future");
        vault.deposit{value: ONE_ETH}(block.timestamp - 1);
    }

    function test_Deposit_RevertIfUnlockTimeIsNow() public {
        vm.expectRevert("Unlock time must be in the future");
        vault.deposit{value: ONE_ETH}(block.timestamp);
    }

    function test_Deposit_StoresCorrectBalance() public {
        uint256 unlockTime = block.timestamp + LOCK_DURATION;
        vault.deposit{value: ONE_ETH}(unlockTime);

        (uint256 balance, uint256 storedUnlockTime, bool active, ) = vault.getVault(owner, 0);
        assertEq(balance, ONE_ETH);
        assertEq(storedUnlockTime, unlockTime);
        assertTrue(active);
    }

    function test_Deposit_MultipleVaults_IncrementIds() public {
        uint256 unlockTime = block.timestamp + LOCK_DURATION;
        uint256 id0 = vault.deposit{value: ONE_ETH}(unlockTime);
        uint256 id1 = vault.deposit{value: 2 ether}(unlockTime);

        assertEq(id0, 0);
        assertEq(id1, 1);
        assertEq(vault.getVaultCount(owner), 2);
    }

    // --- withdraw ---

    function test_Withdraw_SucceedsAfterUnlock() public {
        uint256 unlockTime = block.timestamp + LOCK_DURATION;
        vault.deposit{value: ONE_ETH}(unlockTime);

        vm.warp(unlockTime);

        uint256 balanceBefore = owner.balance;
        vault.withdraw(0);
        assertEq(owner.balance - balanceBefore, ONE_ETH);
    }

    function test_Withdraw_EmitsEvent() public {
        uint256 unlockTime = block.timestamp + LOCK_DURATION;
        vault.deposit{value: ONE_ETH}(unlockTime);

        vm.warp(unlockTime);

        vm.expectEmit(true, false, false, true);
        emit TimeLockV1.Withdrawn(owner, 0, ONE_ETH);
        vault.withdraw(0);
    }

    function test_Withdraw_RevertIfStillLocked() public {
        uint256 unlockTime = block.timestamp + LOCK_DURATION;
        vault.deposit{value: ONE_ETH}(unlockTime);

        vm.expectRevert("Funds are still locked");
        vault.withdraw(0);
    }

    function test_Withdraw_RevertOnInvalidVaultId() public {
        vm.expectRevert("Invalid vault ID");
        vault.withdraw(99);
    }

    function test_Withdraw_RevertIfAlreadyWithdrawn() public {
        uint256 unlockTime = block.timestamp + LOCK_DURATION;
        vault.deposit{value: ONE_ETH}(unlockTime);

        vm.warp(unlockTime);
        vault.withdraw(0);

        vm.expectRevert("Vault is not active");
        vault.withdraw(0);
    }

    function test_Withdraw_DeactivatesVaultAfterWithdraw() public {
        uint256 unlockTime = block.timestamp + LOCK_DURATION;
        vault.deposit{value: ONE_ETH}(unlockTime);

        vm.warp(unlockTime);
        vault.withdraw(0);

        (uint256 balance, , bool active, ) = vault.getVault(owner, 0);
        assertEq(balance, 0);
        assertFalse(active);
    }

    // --- withdrawAll ---

    function test_WithdrawAll_WithdrawsAllUnlocked() public {
        uint256 unlockTime = block.timestamp + LOCK_DURATION;
        vault.deposit{value: ONE_ETH}(unlockTime);
        vault.deposit{value: 2 ether}(unlockTime);

        vm.warp(unlockTime);

        uint256 balanceBefore = owner.balance;
        uint256 total = vault.withdrawAll();

        assertEq(total, 3 ether);
        assertEq(owner.balance - balanceBefore, 3 ether);
    }

    function test_WithdrawAll_SkipsStillLockedVaults() public {
        uint256 unlockSoon = block.timestamp + LOCK_DURATION;
        uint256 unlockLater = block.timestamp + LOCK_DURATION * 10;

        vault.deposit{value: ONE_ETH}(unlockSoon);
        vault.deposit{value: 2 ether}(unlockLater);

        vm.warp(unlockSoon);

        uint256 balanceBefore = owner.balance;
        uint256 total = vault.withdrawAll();

        assertEq(total, ONE_ETH);
        assertEq(owner.balance - balanceBefore, ONE_ETH);

        // Second vault still active and locked
        (, , bool active, ) = vault.getVault(owner, 1);
        assertTrue(active);
    }

    function test_WithdrawAll_RevertIfNoUnlockedFunds() public {
        uint256 unlockTime = block.timestamp + LOCK_DURATION;
        vault.deposit{value: ONE_ETH}(unlockTime);

        vm.expectRevert("No unlocked funds available");
        vault.withdrawAll();
    }

    function test_WithdrawAll_RevertIfNoVaults() public {
        vm.expectRevert("No unlocked funds available");
        vault.withdrawAll();
    }

    // --- view functions ---

    function test_GetVaultCount() public {
        uint256 unlockTime = block.timestamp + LOCK_DURATION;
        vault.deposit{value: ONE_ETH}(unlockTime);
        vault.deposit{value: ONE_ETH}(unlockTime);
        assertEq(vault.getVaultCount(owner), 2);
    }

    function test_GetVaultCount_ZeroForNewUser() public view {
        assertEq(vault.getVaultCount(addr1), 0);
    }

    function test_GetVault_ReturnsCorrectData() public {
        uint256 unlockTime = block.timestamp + LOCK_DURATION;
        vault.deposit{value: ONE_ETH}(unlockTime);

        (uint256 balance, uint256 storedUnlockTime, bool active, bool isUnlocked) =
            vault.getVault(owner, 0);

        assertEq(balance, ONE_ETH);
        assertEq(storedUnlockTime, unlockTime);
        assertTrue(active);
        assertFalse(isUnlocked); // still locked
    }

    function test_GetVault_IsUnlockedAfterTime() public {
        uint256 unlockTime = block.timestamp + LOCK_DURATION;
        vault.deposit{value: ONE_ETH}(unlockTime);

        vm.warp(unlockTime);

        (, , , bool isUnlocked) = vault.getVault(owner, 0);
        assertTrue(isUnlocked);
    }

    function test_GetVault_RevertOnInvalidId() public {
        vm.expectRevert("Invalid vault ID");
        vault.getVault(owner, 99);
    }

    function test_GetTotalBalance() public {
        uint256 unlockTime = block.timestamp + LOCK_DURATION;
        vault.deposit{value: ONE_ETH}(unlockTime);
        vault.deposit{value: 2 ether}(unlockTime);
        assertEq(vault.getTotalBalance(owner), 3 ether);
    }

    function test_GetUnlockedBalance_BeforeAndAfterUnlock() public {
        uint256 unlockTime = block.timestamp + LOCK_DURATION;
        vault.deposit{value: ONE_ETH}(unlockTime);

        assertEq(vault.getUnlockedBalance(owner), 0);

        vm.warp(unlockTime);
        assertEq(vault.getUnlockedBalance(owner), ONE_ETH);
    }

    function test_GetActiveVaults_ReturnsCorrectData() public {
        uint256 unlockTime = block.timestamp + LOCK_DURATION;
        vault.deposit{value: ONE_ETH}(unlockTime);
        vault.deposit{value: 2 ether}(unlockTime);

        (uint256[] memory ids, uint256[] memory balances, uint256[] memory unlockTimes) =
            vault.getActiveVaults(owner);

        assertEq(ids.length, 2);
        assertEq(ids[0], 0);
        assertEq(ids[1], 1);
        assertEq(balances[0], ONE_ETH);
        assertEq(balances[1], 2 ether);
        assertEq(unlockTimes[0], unlockTime);
        assertEq(unlockTimes[1], unlockTime);
    }

    function test_GetAllVaults_ReturnsAllVaults() public {
        uint256 unlockTime = block.timestamp + LOCK_DURATION;
        vault.deposit{value: ONE_ETH}(unlockTime);

        TimeLockV1.Vault[] memory allVaults = vault.getAllVaults(owner);
        assertEq(allVaults.length, 1);
        assertEq(allVaults[0].balance, ONE_ETH);
        assertEq(allVaults[0].unlockTime, unlockTime);
        assertTrue(allVaults[0].active);
    }

    // --- access control ---

    function test_Initialize_OwnerSetCorrectly() public view {
        assertEq(vault.owner(), owner);
    }

    function test_DoubleInit_Reverts() public {
        vm.expectRevert();
        vault.initialize(addr1);
    }

    function test_Upgrade_RevertIfNotOwner() public {
        // Non-owner cannot authorize an upgrade through the proxy
        address newImpl = address(new TimeLockV2());
        vm.prank(addr1);
        vm.expectRevert();
        TimeLockV1(proxy).upgradeToAndCall(newImpl, "");
    }

    // =========================================================
    // 21.2 — Upgrade Path Tests: V1 → V2
    // =========================================================

    function _deployAndPopulate()
        internal
        returns (address _proxy, uint256 vaultId, uint256 unlockTime)
    {
        address impl = address(new TimeLockV1());
        _proxy = UnsafeUpgrades.deployUUPSProxy(
            impl,
            abi.encodeCall(TimeLockV1.initialize, (owner))
        );
        TimeLockV1 v1 = TimeLockV1(_proxy);

        unlockTime = block.timestamp + LOCK_DURATION;
        vaultId = v1.deposit{value: ONE_ETH}(unlockTime);
    }

    function test_Upgrade_VaultBalancePreserved() public {
        (address _proxy, uint256 vaultId, ) = _deployAndPopulate();

        (uint256 balanceBefore, , , ) = TimeLockV1(_proxy).getVault(owner, vaultId);

        UnsafeUpgrades.upgradeProxy(_proxy, address(new TimeLockV2()), "");
        TimeLockV2 vaultV2 = TimeLockV2(_proxy);

        (uint256 balanceAfter, , , ) = vaultV2.getVault(owner, vaultId);
        assertEq(balanceAfter, balanceBefore);
    }

    function test_Upgrade_VaultUnlockTimePreserved() public {
        (address _proxy, uint256 vaultId, uint256 unlockTime) = _deployAndPopulate();

        UnsafeUpgrades.upgradeProxy(_proxy, address(new TimeLockV2()), "");
        TimeLockV2 vaultV2 = TimeLockV2(_proxy);

        (, uint256 storedUnlockTime, , ) = vaultV2.getVault(owner, vaultId);
        assertEq(storedUnlockTime, unlockTime);
    }

    function test_Upgrade_VaultActiveStatePreserved() public {
        (address _proxy, uint256 vaultId, ) = _deployAndPopulate();

        UnsafeUpgrades.upgradeProxy(_proxy, address(new TimeLockV2()), "");
        TimeLockV2 vaultV2 = TimeLockV2(_proxy);

        (, , bool active, ) = vaultV2.getVault(owner, vaultId);
        assertTrue(active);
    }

    function test_Upgrade_VaultCountPreserved() public {
        (address _proxy, , ) = _deployAndPopulate();

        // Add a second vault before upgrade
        TimeLockV1(_proxy).deposit{value: 2 ether}(block.timestamp + LOCK_DURATION);

        UnsafeUpgrades.upgradeProxy(_proxy, address(new TimeLockV2()), "");
        TimeLockV2 vaultV2 = TimeLockV2(_proxy);

        assertEq(vaultV2.getVaultCount(owner), 2);
    }

    function test_Upgrade_OwnerPreserved() public {
        (address _proxy, , ) = _deployAndPopulate();

        UnsafeUpgrades.upgradeProxy(_proxy, address(new TimeLockV2()), "");
        TimeLockV2 vaultV2 = TimeLockV2(_proxy);

        assertEq(vaultV2.owner(), owner);
    }

    // --- extendLock happy path ---

    function test_ExtendLock_HappyPath() public {
        (address _proxy, uint256 vaultId, uint256 originalUnlockTime) = _deployAndPopulate();

        UnsafeUpgrades.upgradeProxy(_proxy, address(new TimeLockV2()), "");
        TimeLockV2 vaultV2 = TimeLockV2(_proxy);

        uint256 newUnlockTime = originalUnlockTime + 500;

        vm.expectEmit(true, false, false, true);
        emit TimeLockV2.LockExtended(owner, vaultId, newUnlockTime);

        vaultV2.extendLock(vaultId, newUnlockTime);

        (, uint256 storedUnlockTime, , ) = vaultV2.getVault(owner, vaultId);
        assertEq(storedUnlockTime, newUnlockTime);
    }

    function test_ExtendLock_NewUnlockTimeStrictlyGreater() public {
        (address _proxy, uint256 vaultId, uint256 originalUnlockTime) = _deployAndPopulate();

        UnsafeUpgrades.upgradeProxy(_proxy, address(new TimeLockV2()), "");
        TimeLockV2 vaultV2 = TimeLockV2(_proxy);

        uint256 newUnlockTime = originalUnlockTime + 1;
        vaultV2.extendLock(vaultId, newUnlockTime);

        (, uint256 storedUnlockTime, , ) = vaultV2.getVault(owner, vaultId);
        assertGt(storedUnlockTime, originalUnlockTime);
    }

    // --- extendLock revert cases ---

    function test_ExtendLock_RevertOnInvalidVaultId() public {
        (address _proxy, , ) = _deployAndPopulate();

        UnsafeUpgrades.upgradeProxy(_proxy, address(new TimeLockV2()), "");
        TimeLockV2 vaultV2 = TimeLockV2(_proxy);

        vm.expectRevert("Invalid vault ID");
        vaultV2.extendLock(99, block.timestamp + 9999);
    }

    function test_ExtendLock_RevertIfVaultNotActive() public {
        (address _proxy, uint256 vaultId, uint256 unlockTime) = _deployAndPopulate();

        // Withdraw to deactivate the vault
        vm.warp(unlockTime);
        TimeLockV1(_proxy).withdraw(vaultId);

        UnsafeUpgrades.upgradeProxy(_proxy, address(new TimeLockV2()), "");
        TimeLockV2 vaultV2 = TimeLockV2(_proxy);

        vm.expectRevert("Vault is not active");
        vaultV2.extendLock(vaultId, unlockTime + 1000);
    }

    function test_ExtendLock_RevertIfNewTimeNotGreater() public {
        (address _proxy, uint256 vaultId, uint256 originalUnlockTime) = _deployAndPopulate();

        UnsafeUpgrades.upgradeProxy(_proxy, address(new TimeLockV2()), "");
        TimeLockV2 vaultV2 = TimeLockV2(_proxy);

        // Equal to current unlock time — should revert
        vm.expectRevert("New unlock time must be greater");
        vaultV2.extendLock(vaultId, originalUnlockTime);
    }

    function test_ExtendLock_RevertIfNewTimeLessThanCurrent() public {
        (address _proxy, uint256 vaultId, uint256 originalUnlockTime) = _deployAndPopulate();

        UnsafeUpgrades.upgradeProxy(_proxy, address(new TimeLockV2()), "");
        TimeLockV2 vaultV2 = TimeLockV2(_proxy);

        vm.expectRevert("New unlock time must be greater");
        vaultV2.extendLock(vaultId, originalUnlockTime - 1);
    }

    function test_ExtendLock_DoesNotAffectOtherVaults() public {
        (address _proxy, , uint256 unlockTime) = _deployAndPopulate();

        // Add a second vault
        uint256 vault1Id = TimeLockV1(_proxy).deposit{value: 2 ether}(unlockTime);

        UnsafeUpgrades.upgradeProxy(_proxy, address(new TimeLockV2()), "");
        TimeLockV2 vaultV2 = TimeLockV2(_proxy);

        // Extend vault 0 only
        vaultV2.extendLock(0, unlockTime + 500);

        // Vault 1 unlock time should be unchanged
        (, uint256 vault1UnlockTime, , ) = vaultV2.getVault(owner, vault1Id);
        assertEq(vault1UnlockTime, unlockTime);
    }

    // =========================================================
    // 21.3 — Fuzz Test: extendLock Never Decreases UnlockTime
    // Feature: oz-upgradeable-v1-v2, Property 5: extendLock Never Decreases UnlockTime
    // =========================================================

    function test_fuzz_TimeLock_ExtendLockNeverDecreases(uint256 extraTime) public {
        // Bound extraTime to [1, 365 days]
        extraTime = bound(extraTime, 1, 365 days);

        // Deploy fresh V1 proxy and upgrade to V2
        address impl = address(new TimeLockV1());
        address _proxy = UnsafeUpgrades.deployUUPSProxy(
            impl,
            abi.encodeCall(TimeLockV1.initialize, (owner))
        );

        uint256 unlockTime = block.timestamp + LOCK_DURATION;
        uint256 vaultId = TimeLockV1(_proxy).deposit{value: ONE_ETH}(unlockTime);

        // Record original unlock time
        (, uint256 originalUnlockTime, , ) = TimeLockV1(_proxy).getVault(owner, vaultId);

        // Upgrade to V2
        UnsafeUpgrades.upgradeProxy(_proxy, address(new TimeLockV2()), "");
        TimeLockV2 vaultV2 = TimeLockV2(_proxy);

        // Extend lock by extraTime
        uint256 newUnlockTime = originalUnlockTime + extraTime;
        vaultV2.extendLock(vaultId, newUnlockTime);

        // Assert new unlock time is strictly greater than original
        (, uint256 storedUnlockTime, , ) = vaultV2.getVault(owner, vaultId);
        assertGt(storedUnlockTime, originalUnlockTime);
        assertEq(storedUnlockTime, newUnlockTime);
    }
}
