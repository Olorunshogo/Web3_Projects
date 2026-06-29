// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

contract TimelockSavings {

    struct Vault {
        uint256 amount;
        uint256 unlockTime;
        bool active;
    }

    mapping(address => Vault) public vaults;

    event Deposited(address user, uint256 amount, uint256 unlockTime);
    event Withdrawn(address user, uint256 amount);

    function deposit(uint256 unlockTime) external payable {
        require(msg.value > 0, "Send ETH");
        require(!vaults[msg.sender].active, "Vault active");

        vaults[msg.sender] = Vault({
            amount: msg.value,
            unlockTime: unlockTime,
            active: true
        });

        emit Deposited(msg.sender, msg.value, unlockTime);
    }

    function withdraw() external {

        Vault storage v = vaults[msg.sender];

        require(v.active, "No vault");
        require(block.timestamp >= v.unlockTime, "Too early");

        uint256 amount = v.amount;

        v.amount = 0;
        v.active = false;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    function getVault(address user)
        external
        view
        returns (uint256 amount, uint256 unlockTime, bool active)
    {
        Vault memory v = vaults[user];
        return (v.amount, v.unlockTime, v.active);
    }
}