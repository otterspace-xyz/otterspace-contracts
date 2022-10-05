#!/usr/bin/env bash

# $1: the name of the .env file to use
source $1

echo "NEXT_OWNER=$NEXT_OWNER"
echo "RAFT_NAME=$RAFT_NAME"
echo "RAFT_SYMBOL=$RAFT_SYMBOL"
echo "DEPLOYER_PRIVATE_KEY=$DEPLOYER_PRIVATE_KEY"
echo "GOERLI_RPC_URL=$GOERLI_RPC_URL"
echo "ETHERSCAN_API_KEY=$ETHERSCAN_API_KEY"
echo "OPTIMISTIC_ETHERSCAN_API_KEY=$OPTIMISTIC_ETHERSCAN_API_KEY"
echo "OPTIMISM_RPC_URL=$OPTIMISM_RPC_URL"

forge create src/Raft.sol:Raft --constructor-args $NEXT_OWNER $RAFT_NAME $RAFT_SYMBOL --private-key $DEPLOYER_PRIVATE_KEY --verify --rpc-url $ETH_RPC_URL --etherscan-api-key $ETHERSCAN_API_KEY
