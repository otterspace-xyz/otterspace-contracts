#!/usr/bin/env bash
# $1: the name of the .env file to use
source $1
forge create src/Badges.sol:Badges --constructor-args $BADGES_NAME $BADGES_SYMBOL $BADGES_VERSION --private-key $PRIVATE_KEY --verify --rpc-url $ETH_RPC_URL --etherscan-api-key $ETHERSCAN_API_KEY
