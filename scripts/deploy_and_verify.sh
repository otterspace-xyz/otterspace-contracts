#!/usr/bin/env bash
source .env
forge create src/$CONTRACT_NAME.sol:$CONTRACT_NAME --constructor-args $CONSTRUCTOR_ARGS --private-key $PRIVATE_KEY --verify --rpc-url $ETH_RPC_URL --etherscan-api-key $ETHERSCAN_API_KEY
