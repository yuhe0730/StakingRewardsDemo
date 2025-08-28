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

import {Test, console} from "forge-std/Test.sol";
import {StakingRewards} from "src/StakingRewards.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract StakingRewardsTest is Test {
    StakingRewards public stakingRewards;
    MyToken public stakingToken;
    MyToken public rewardsToken;

    address public user = address(1);
    uint256 public initialBalance = 1000 ether;
    uint256 public rewardAmount = 100 ether;
    uint256 public rewardsDuration = 30 seconds;

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

    function setUp() public {
        stakingToken = new MyToken("Stake Token", "STK");
        rewardsToken = new MyToken("Reward Token", "RWD");

        stakingRewards = new StakingRewards(
            address(stakingToken),
            address(rewardsToken)
        );

        stakingToken.mint(user, initialBalance);
        rewardsToken.mint(address(stakingRewards), rewardAmount);

        vm.startPrank(user);
        stakingToken.approve(address(stakingRewards), type(uint256).max);
        vm.stopPrank();

        stakingRewards.setRewardsDuration(rewardsDuration);
        stakingRewards.notifyRewardAmount(rewardAmount);
    }

    function testInitialSetup() public {
        assertEq(stakingToken.balanceOf(user), initialBalance);
        assertEq(rewardsToken.balanceOf(address(stakingRewards)), rewardAmount);
        assertEq(stakingRewards.duration(), rewardsDuration);
    }

    function testStake() public {
        uint256 stakeAmount = 100 ether;

        vm.startPrank(user);

        vm.expectEmit(true, false, false, true);
        emit Staked(user, stakeAmount);
        stakingRewards.stake(stakeAmount);

        assertEq(stakingToken.balanceOf(user), initialBalance - stakeAmount);
        assertEq(stakingToken.balanceOf(address(stakingRewards)), stakeAmount);
        assertEq(stakingRewards.balanceOf(user), stakeAmount);

        vm.stopPrank();
    }

    function testStakeZeroAmountReverts() public {
        vm.startPrank(user);

        vm.expectRevert(StakeAmountIsZero.selector);
        stakingRewards.stake(0);

        vm.stopPrank();
    }

    function testWithdraw() public {
        uint256 stakeAmount = 200 ether;

        vm.startPrank(user);
        stakingRewards.stake(stakeAmount);

        vm.expectEmit(true, false, false, true);
        emit Withdrawn(user, stakeAmount);
        stakingRewards.withdraw(stakeAmount);

        assertEq(stakingToken.balanceOf(user), initialBalance);
        assertEq(stakingToken.balanceOf(address(stakingRewards)), 0);
        assertEq(stakingRewards.balanceOf(user), 0);

        vm.stopPrank();
    }

    function testWithdrawZeroAmountReverts() public {
        vm.startPrank(user);

        vm.expectRevert(WithdrawAmountIsZero.selector);
        stakingRewards.withdraw(0);

        vm.stopPrank();
    }

    function testWithdrawMoreThanStakedReverts() public {
        uint256 stakeAmount = 100 ether;
        uint256 withdrawAmount = 200 ether;

        vm.startPrank(user);
        stakingRewards.stake(stakeAmount);

        vm.expectRevert(InsufficientBalanceAmount.selector);
        stakingRewards.withdraw(withdrawAmount);

        vm.stopPrank();
    }

    function testGetReward() public {
        uint256 stakeAmount = 100 ether;
        uint256 expectRewardAmount = 50 ether;

        vm.startPrank(user);
        stakingRewards.stake(stakeAmount);

        vm.warp(block.timestamp + rewardsDuration / 2);

        uint256 earned = stakingRewards.earned(user);
        assertApproxEqAbs(earned, expectRewardAmount, 1e5);

        uint256 rewardsBalanceBefore = rewardsToken.balanceOf(user);

        vm.expectEmit(true, false, false, true);
        emit RewardPaid(user, earned);
        stakingRewards.getReward();

        uint256 rewardsBalanceAfter = rewardsToken.balanceOf(user);
        assertEq(rewardsBalanceAfter - rewardsBalanceBefore, earned);

        vm.stopPrank();
    }

    function testGetRewardWithoutStake() public {
        vm.startPrank(user);

        vm.expectRevert(RewardAmountIsZero.selector);
        stakingRewards.getReward();

        vm.stopPrank();
    }

    function testNotifyRewardAmount() public {
        uint256 newRewardAmount = 1000 ether;
        rewardsToken.mint(address(stakingRewards), newRewardAmount);

        stakingRewards.notifyRewardAmount(newRewardAmount);

        assertApproxEqAbs(
            stakingRewards.rewardRate() * rewardsDuration,
            newRewardAmount + rewardAmount,
            1e5
        );
    }

    function testNotifyRewardAmountZeroReverts() public {
        vm.expectRevert(NotifyRewardAmountIsZero.selector);
        stakingRewards.notifyRewardAmount(0);
    }

    function testSetRewardsDuration() public {
        uint256 newDuration = 30 seconds;

        vm.warp(block.timestamp + rewardsDuration + 1);
        stakingRewards.setRewardsDuration(newDuration);

        assertEq(stakingRewards.duration(), newDuration);
    }

    function testSetRewardsDurationWhileActiveReverts() public {
        uint256 newDuration = 30 seconds;

        vm.expectRevert(RewardDurationNotFinished.selector);
        stakingRewards.setRewardsDuration(newDuration);
    }

    function testRewardRate() public {
        uint256 rewardRate = stakingRewards.rewardRate();

        assertApproxEqAbs(rewardRate * rewardsDuration, rewardAmount, 1e12);
    }

    function testRewardPerTokenUpdates() public {
        uint256 stakeAmount = 100 ether;
        uint256 timePassedRatio = 2;

        vm.prank(user);
        stakingRewards.stake(stakeAmount);
        uint256 rewardPerTokenBefore = stakingRewards.rewardPerToken();
        vm.warp(block.timestamp + rewardsDuration / timePassedRatio);
        uint256 rewardPerToken = stakingRewards.rewardPerToken();

        assertApproxEqAbs(
            rewardPerToken - rewardPerTokenBefore,
            ((rewardAmount / timePassedRatio) * 1e18) / stakeAmount,
            1e5
        );
    }

    function testLastTimeRewardApplicable() public {
        uint256 finishAt = stakingRewards.finishAt();
        assertEq(block.timestamp + rewardsDuration, finishAt);

        uint256 applicableBefore = stakingRewards.lastTimeRewardApplicable();
        assertEq(applicableBefore, block.timestamp);

        vm.warp(finishAt + 10);
        uint256 applicableAfter = stakingRewards.lastTimeRewardApplicable();
        assertEq(applicableAfter, finishAt);
    }
}
