#!/usr/bin/env bash
# $1: the name of the .env file to use
source $1
forge create src/Raft.sol:Raft --constructor-args $OWNER_ADDRESS $NAME $SYMBOL --private-key $PRIVATE_KEY --verify --rpc-url $ETH_RPC_URL --etherscan-api-key $ETHERSCAN_API_KEY
