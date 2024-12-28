# StakeSafe

A secure staking platform for crypto assets built on the Stacks blockchain. This contract allows users to:

- Stake tokens for a specified time period
- Earn rewards based on staking duration and amount
- Withdraw stakes after lock period expires
- View staking stats and rewards

## Features

- Minimum staking period enforcement
- Reward calculation based on time staked
- Emergency withdrawal with penalty
- View functions for staking stats

## Security

The contract includes various safety checks and requires:
- Minimum stake amount
- Lock period validation 
- Owner-only admin functions
- Withdrawal timelock