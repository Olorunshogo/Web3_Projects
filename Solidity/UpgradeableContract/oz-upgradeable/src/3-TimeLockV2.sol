// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TimeLockV1} from "./3-TimeLockV1.sol";

/// @custom:oz-upgrades-from TimeLockV1
contract TimeLockV2 is TimeLockV1 {
    event LockExtended(address indexed user, uint256 vaultId, uint256 newUnlockTime);

    /// @notice Extend the lock time on an active vault
    /// @param _vaultId The vault to extend
    /// @param _newUnlockTime Must be strictly greater than the current unlock time
    function extendLock(uint256 _vaultId, uint256 _newUnlockTime) external {
        require(_vaultId < vaults[msg.sender].length, "Invalid vault ID");

        Vault storage vault = vaults[msg.sender][_vaultId];
        require(vault.active, "Vault is not active");
        require(_newUnlockTime > vault.unlockTime, "New unlock time must be greater");

        vault.unlockTime = _newUnlockTime;

        emit LockExtended(msg.sender, _vaultId, _newUnlockTime);
    }
}
