#!/usr/bin/env bash
# $1: the name of the .env file to use
source $1
forge create src/Raft.sol:Raft --constructor-args $RAFT_OWNER_ADDRESS $RAFT_NAME $RAFT_SYMBOL --private-key $DEPLOYER_PRIVATE_KEY --verify --rpc-url $ETH_RPC_URL --etherscan-api-key $ETHERSCAN_API_KEY
