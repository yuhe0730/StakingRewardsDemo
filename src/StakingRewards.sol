// SPDX-License-Identifier: MIT
// Contract elements should be laid out in the following order:
// Pragma statements
// Import statements
// Events
// Errors
// Interfaces
// Libraries
// Contracts
// Inside each contract, library or interface, use the following order:
// Type declarations
// State variables
// Events
// Errors
// Modifiers
// Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract StakingRewards is ReentrancyGuard {
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;

    address public owner;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    uint256 public finishAt;
    uint256 public updatedAt;
    uint256 public duration;
    uint256 public rewardRate;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    error StakeAmountIsZero();
    error WithdrawAmountIsZero();
    error RewardAmountIsZero();
    error RewardDurationIsZero();
    error InvalidOwner();
    error NotifyRewardAmountIsZero();
    error RewardRateIsZero();
    error RewardDurationNotFinished();
    error InsufficientRewardAmount();
    error InsufficientBalanceAmount();

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }

        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert InvalidOwner();
        }

        _;
    }

    constructor(address _stakingToken, address _rewardsToken) {
        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
    }

    function stake(
        uint256 _amount
    ) external nonReentrant updateReward(msg.sender) {
        if (_amount == 0) {
            revert StakeAmountIsZero();
        }

        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;

        stakingToken.transferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }

    function withdraw(
        uint256 _amount
    ) external nonReentrant updateReward(msg.sender) {
        if (_amount == 0) {
            revert WithdrawAmountIsZero();
        }
        if (balanceOf[msg.sender] < _amount) {
            revert InsufficientBalanceAmount();
        }

        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        stakingToken.transfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount);
    }

    function getReward() external nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward == 0) {
            revert RewardAmountIsZero();
        }

        rewards[msg.sender] = 0;
        rewardsToken.transfer(msg.sender, reward);
        emit RewardPaid(msg.sender, reward);
    }

    function setRewardsDuration(uint256 _duration) external onlyOwner {
        if (finishAt >= block.timestamp) {
            revert RewardDurationNotFinished();
        }
        duration = _duration;
    }

    function notifyRewardAmount(
        uint256 _amount
    ) external onlyOwner updateReward(address(0)) {
        if (_amount == 0) {
            revert NotifyRewardAmountIsZero();
        }
        if (duration == 0) {
            revert RewardDurationIsZero();
        }

        if (block.timestamp >= finishAt) {
            rewardRate = _amount / duration;
        } else {
            uint256 remaining = rewardRate * (finishAt - block.timestamp);
            rewardRate = (remaining + _amount) / duration;
        }

        if (rewardRate == 0) {
            revert RewardRateIsZero();
        }
        if (rewardRate * duration > rewardsToken.balanceOf(address(this))) {
            revert InsufficientRewardAmount();
        }

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalSupply;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, finishAt);
    }

    function earned(address _account) public view returns (uint256) {
        return
            ((balanceOf[_account] *
                (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) +
            rewards[_account];
    }
}
