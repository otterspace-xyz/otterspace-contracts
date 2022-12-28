#!/usr/bin/env bash

# call this script like this:
# ./scripts/deploy_and_verify_badges.sh .env.badges goerli

# we took this out since we dont need to pass in an .env file since we're running it from GH actions
# $1: the name of the .env file to use

echo "1: $1"
echo "2: $2"
echo "DEPLOYER_PRIVATE_KEY=$DEPLOYER_PRIVATE_KEY"

if [ "$2" == "goerli" ]; then
  echo " "
  echo "GOERLI_RPC_URL=$GOERLI_RPC_URL"
  echo "ETHERSCAN_API_KEY=$ETHERSCAN_API_KEY"
  forge create src/$1.sol:$1 --private-key $DEPLOYER_PRIVATE_KEY --verify --rpc-url $GOERLI_RPC_URL --etherscan-api-key $ETHERSCAN_API_KEY
elif [ "$2" == "optimism" ]; then
  echo " "
  echo "OPTIMISTIC_ETHERSCAN_API_KEY=$OPTIMISTIC_ETHERSCAN_API_KEY"
  echo "OPTIMISM_RPC_URL=$OPTIMISM_RPC_URL"
  forge create src/$1.sol:$1 --private-key $DEPLOYER_PRIVATE_KEY --verify --rpc-url $OPTIMISM_RPC_URL --etherscan-api-key $OPTIMISTIC_ETHERSCAN_API_KEY
fi
