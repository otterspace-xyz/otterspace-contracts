#!/usr/bin/env bash
# $1: the name of the .env file to use
source $1
echo $DEPLOYER_PRIVATE_KEY
echo $CHAIN_ID
echo $ETH_RPC_URL
echo $CONTRACT_NAME
echo $BADGES_NAME
echo $BADGES_SYMBOL
echo $BADGES_VERSION
echo $ETHERSCAN_API_KEY
forge create src/Badges.sol:Badges --constructor-args $BADGES_NAME $BADGES_SYMBOL $BADGES_VERSION $RAFT_ADDRESS $NEXT_OWNER --private-key $DEPLOYER_PRIVATE_KEY --verify --rpc-url $ETH_RPC_URL --etherscan-api-key $ETHERSCAN_API_KEY
