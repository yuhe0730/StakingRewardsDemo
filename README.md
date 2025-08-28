## stakingRewardsDemo

### Project Overview
This is a demo implementation of an StakingRewards contract built with Solidity and Foundry.

I hope this demo can help me find a junior job :)

stakingRewardsDemo is a Solidity project demonstrating a Synthetix-style staking rewards mechanism. It allows users to stake a custom ERC20 token and earn rewards in another ERC20 token over time. Rewards accrue linearly based on stake: each second, a user’s earned reward = (rewardRate × userStake) / totalStaked ￼. This project is designed as a junior Solidity developer’s portfolio piece, highlighting understanding of staking logic and reward accounting.

Built with Foundry (Forge) for development and testing, the repository includes a StakingRewards contract with functions for staking, withdrawing, and claiming rewards. The contract owner can fund the rewards pool and set the reward rate.  The project also includes a deployment script that reads PRIVATE_KEY, STAKING_TOKEN_ADDRESS, and REWARDS_TOKEN_ADDRESS from the environment. The contract has been deployed and verified on the Sepolia testnet, demonstrating a complete deployment workflow.

### Features
-	Staking & Withdrawal: Users can stake the specified ERC20 token and withdraw their stake at any time.
-	Reward Accrual: Stakers earn rewards every second based on a fixed rewardRate, distributed proportionally to each user’s stake ￼.
-	Owner-Funded Rewards: The contract owner can deposit reward tokens into the contract to fund the reward pool.
-	Reward Claiming: Users can claim their accumulated rewards on demand; rewards are updated on every stake, withdraw, or claim action.
-	Error Handling: The contract includes checks (using require) to prevent invalid operations (e.g. staking or claiming zero tokens).
-	Testnet Deployment: Scripts are provided for deploying to Sepolia, and the source code is verified on Etherscan after deployment.

### Tech Stack
-	Solidity (>=0.8.x): Language for writing the smart contracts.
-	Foundry (Forge/Anvil/Cast): Used for building, testing, and deploying the contracts ￼. 
-	OpenZeppelin Contracts: Industry-standard library used for the ERC20 token implementations, ensuring robust and secure token behavior ￼.
-	Sepolia Testnet: Ethereum test network used for deployment and verification.
-	GitHub & Etherscan: Repository hosting and contract verification (via Foundry’s verification tool).

### Project Structure
```
stakingRewardsDemo/
├── src/
│   └── StakingRewards.sol       # Main staking rewards contract
├── test/
│   └── StakingRewards.t.sol     # Foundry unit tests (normal and edge cases)
├── script/
│   └── DeployStaking.s.sol      # Deployment script 
├── foundry.toml                 # Foundry configuration (compiler settings, etc.)
└── README.md                    # Project documentation (this file)
```
### Getting Started
1.	Clone the Repository:

`git clone https://github.com/yuhe0730/StakingRewardsDemo`

`cd stakingRewardsDemo`

2.	Set Environment Variables: Create a .env file (or export variables) with the following:

```
PRIVATE_KEY=0x<your_private_key>
SEPOLIA_RPC_URL=<your_sepolia_url>
ETHERSCAN_API_KEY=<your_etherscan_api_key>
STAKING_TOKEN_ADDRESS=<deployed_staking_token_address>
REWARDS_TOKEN_ADDRESS=<deployed_rewards_token_address>
```

3.	Build Contracts: Compile the contracts with Foundry:
   
`forge build`

<img width="928" height="424" alt="image" src="https://github.com/user-attachments/assets/3eb424df-bf2c-466d-a3cd-20e3439e75da" />

4.  Test & Deploy
   
- Run Tests: Execute the full test suite with Foundry:
  
`forge test`

<img width="1428" height="614" alt="image" src="https://github.com/user-attachments/assets/616a4f4a-b07f-452c-b055-95e7ad0378ce" />

`forge coverage`

<img width="1150" height="816" alt="image" src="https://github.com/user-attachments/assets/4fe5a873-09f4-4707-bd0c-35c18ff17311" />

-	Deploy to Sepolia: Use the provided Foundry script. For example:
  
`source .env`

`forge script script/DeployStaking.s.sol --rpc-url ${SEPOLIA_RPC_URL} --broadcast`

- Verify Contract: After deployment, verify the contract on Etherscan.
  
`source .env`

`forge verify-contract --chain-id  11155111 --etherscan-api-key ${ETHERSCAN_API_KEY} <contract_address> src/StakingRewards.sol:StakingRewards`

**Example contract (deployed on Sepolia, have verified): 0x66CA707065F392CaC31971ECbb88CC3F3E3c1041**

**StakingToken address: 0x5ce6290A3923f82A302f2fdEfFbB92Ed8eA2D023**

**RewardsToken address: 0x55d1632087b123E0988CE2c718ba30A5502Eb697**

Ensure you set ETHERSCAN_API_KEY in your environment. This will submit the source to Etherscan so that anyone can view and verify the code.


### License

This project is released under the MIT License.
