#!/usr/bin/env bash
source .env.rinkeby
forge create src/Badges.sol:Badges --constructor-args $BADGES_NAME $BADGES_SYMBOL $BADGES_VERSION --private-key $PRIVATE_KEY --verify --rpc-url $ETH_RPC_URL --etherscan-api-key $ETHERSCAN_API_KEY
