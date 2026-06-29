
Task Overview

Track A requires us to design a DeFi staking protocol that involves staking an ERC-20 token, earning rewards over time, and handling withdrawals in a secure manner. Users will stake a token, receive a receipt token, and claim their staked amount and rewards. The contract should also allow checking the amount of rewards accumulated, prevent issues like reentrancy attacks, and ensure proper edge-case handling.

We need to deploy three ERC-20 tokens:

Main Token – The token that users will stake.

Reward Token – The token used for staking rewards.

Receipt Token – A token given to users when they stake; users return this token to withdraw their stake + rewards.

Key Functional Requirements

Staking (stake(uint256 amount))

Transfer the main token from the user to the contract.

Update internal accounting to track the staked amount and time.

Require the user to give ERC-20 approval for token transfer.

Reward Distribution (claimRewards() & internal reward accrual)

Implement time-based reward accrual proportional to the amount staked.

Reward distribution should stop when the staked amount is withdrawn.

Rewards should be claimable separately.

Withdrawals (withdraw(uint256 amount))

Ensure users can withdraw their staked amount + rewards.

Prevent over-withdrawals by tracking what the user has staked and earned.

Reset rewards before withdrawal.

Helper Functions (getNextWithdrawTime() and getRewardBalance())

getRewardBalance() should return the user's earned rewards.

getNextWithdrawTime() should return the time when the user can withdraw based on lock periods.

Receipt Token Logic

Upon staking, mint a receipt token to the user's address, representing their stake.

When the user wishes to withdraw, they must return the receipt token to claim their staked amount + rewards.

Advanced Requirements (Bonus)

Emergency Withdrawal (emergencyWithdraw()): Users can withdraw their stake without rewards in case of an emergency.

Reward Rate Updates: Add a function to update the reward rate.

Lock Period: Implement a lock period that restricts withdrawals until a certain amount of time has passed.

Penalty System: Penalize users who withdraw before the lock period ends.

Multiple Staking Pools: Allow users to stake into different pools, each with distinct reward rates.

Security Considerations

Reentrancy Attack Protection:

Use the checks-effects-interactions pattern to ensure the contract state is updated before transferring tokens.

Use ReentrancyGuard to prevent reentrancy attacks when users withdraw or claim rewards.

Reentrancy on Withdrawals:

Ensure users cannot re-enter the contract and withdraw additional funds by locking critical functions (e.g., withdraw() and claimRewards()).

Approval/Transfer Checks:

Ensure users have sufficient approval to transfer the main token and reward token.

Avoid errors where users might attempt to withdraw more than they are entitled to (use proper accounting).

Access Control:

Only the contract owner should be able to change reward rates, update the lock period, or perform emergency functions.

Edge Case Handling:

Users should not be able to withdraw or claim rewards more than once for the same staked amount (no double-spending).

Handle users who have zero balance, or haven't staked anything.

## Sample Staking Contract Outline
```bash
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./ERC20.sol";  // Import the ERC20 token interface

contract StakingPool {

    // Token declarations
    ERC20 public mainToken; // The token users stake
    ERC20 public rewardToken; // The token users earn as rewards
    ERC20 public receiptToken; // The receipt token that represents the user's stake

    // State variables
    mapping(address => uint256) public stakedAmount;  // Amount staked by each user
    mapping(address => uint256) public rewardBalance; // Rewards earned by each user
    mapping(address => uint256) public lastStakedTime; // Last time the user staked
    mapping(address => uint256) public receiptBalances; // Balance of receipt tokens

    uint256 public rewardRate; // Reward rate (e.g., tokens per block)
    uint256 public lockPeriod; // Lock period (in seconds)

    uint256 public totalStaked; // Total staked amount in the pool
    uint256 public totalRewardsAccrued; // Total rewards accrued by users

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 reward);
    event RewardRateUpdated(uint256 newRewardRate);
    event LockPeriodUpdated(uint256 newLockPeriod);

    constructor(
        address _mainToken,
        address _rewardToken,
        address _receiptToken,
        uint256 _rewardRate,
        uint256 _lockPeriod
    ) {
        mainToken = ERC20(_mainToken);
        rewardToken = ERC20(_rewardToken);
        receiptToken = ERC20(_receiptToken);
        rewardRate = _rewardRate;
        lockPeriod = _lockPeriod;
    }

    // Stake function
    function stake(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(mainToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        // Mint receipt tokens to represent the user's stake
        receiptToken.mint(msg.sender, _amount);

        // Update staking and reward balances
        stakedAmount[msg.sender] += _amount;
        totalStaked += _amount;
        lastStakedTime[msg.sender] = block.timestamp;

        emit Staked(msg.sender, _amount);
    }

    // Claim rewards function
    function claimRewards() external {
        uint256 reward = rewardBalance[msg.sender];
        require(reward > 0, "No rewards to claim");

        // Transfer reward to user
        rewardBalance[msg.sender] = 0;
        totalRewardsAccrued -= reward;
        require(rewardToken.transfer(msg.sender, reward), "Reward transfer failed");

        emit RewardsClaimed(msg.sender, reward);
    }

    // Withdraw function
    function withdraw(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(stakedAmount[msg.sender] >= _amount, "Insufficient staked balance");

        // Calculate accrued rewards before updating the state
        uint256 rewards = calculateRewards(msg.sender);

        // Deduct staked amount and rewards
        stakedAmount[msg.sender] -= _amount;
        rewardBalance[msg.sender] += rewards;

        // Burn receipt tokens as the user withdraws
        receiptToken.burnFrom(msg.sender, _amount);

        totalStaked -= _amount;

        // Transfer main token and rewards to user
        require(mainToken.transfer(msg.sender, _amount), "Transfer failed");
        require(rewardToken.transfer(msg.sender, rewards), "Reward transfer failed");

        emit Withdrawn(msg.sender, _amount);
    }

    // Calculate rewards based on the staked amount and time
    function calculateRewards(address _user) internal view returns (uint256) {
        uint256 stakedTime = block.timestamp - lastStakedTime[_user];
        uint256 rewards = (stakedAmount[_user] * rewardRate * stakedTime) / 1e18;
        return rewards;
    }

    // Helper function to get the next withdraw time
    function getNextWithdrawTime(address _user) external view returns (uint256) {
        return lastStakedTime[_user] + lockPeriod;
    }

    // Update reward rate (admin only)
    function updateRewardRate(uint256 _newRewardRate) external onlyOwner {
        rewardRate = _newRewardRate;
        emit RewardRateUpdated(_newRewardRate);
    }

    // Update lock period (admin only)
    function updateLockPeriod(uint256 _newLockPeriod) external onlyOwner {
        lockPeriod = _newLockPeriod;
        emit LockPeriodUpdated(_newLockPeriod);
    }

    // Emergency withdraw (admin only)
    function emergencyWithdraw(uint256 _amount) external onlyOwner {
        require(_amount <= totalStaked, "Not enough liquidity");
        require(mainToken.transfer(msg.sender, _amount), "Emergency transfer failed");
    }

    // Modifier to check if caller is the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner(), "Not the contract owner");
        _;
    }

    // Helper to get contract owner
    function owner() public view returns (address) {
        return address(this); // Example placeholder; in a real implementation, this would be the actual contract owner.
    }
}
```
### Tests
#### Staking Test:
```solidity
// Tests for staking function

function testStake() public {
    uint256 stakeAmount = 1000;

    // Arrange
    address staker = address(0x123);
    uint256 initialBalance = mainToken.balanceOf(staker);

    // Act
    stakingPool.stake(stakeAmount);

    // Assert
    assertEq(stakingPool.stakedAmount(staker), stakeAmount);
    assertEq(mainToken.balanceOf(staker), initialBalance - stake
```





