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

import {Script, console} from "forge-std/Script.sol";
import {StakingRewards} from "src/StakingRewards.sol";

contract StakingRewardsScript is Script {
    StakingRewards public stakingRewards;
    address public stakingTokenAddress;
    address public rewardsTokenAddress;

    function run() public {
        uint256 deployPrivateKey = vm.envUint("PRIVATE_KEY");
        stakingTokenAddress = vm.envAddress("STAKING_TOKEN_ADDRESS");
        rewardsTokenAddress = vm.envAddress("REWARDS_TOKEN_ADDRESS");

        vm.startBroadcast(deployPrivateKey);
        stakingRewards = new StakingRewards(
            stakingTokenAddress,
            rewardsTokenAddress
        );

        vm.stopBroadcast();
    }
}
