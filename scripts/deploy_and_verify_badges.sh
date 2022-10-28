#!/usr/bin/env bash

# call this script like this:
# ./scripts/deploy_and_verify_badges.sh .env.badges goerli

# $1: the name of the .env file to use
source $1

echo "DEPLOYER_PRIVATE_KEY=$DEPLOYER_PRIVATE_KEY"
echo "GOERLI_RPC_URL=$GOERLI_RPC_URL"
echo "ETHERSCAN_API_KEY=$ETHERSCAN_API_KEY"
echo "OPTIMISTIC_ETHERSCAN_API_KEY=$OPTIMISTIC_ETHERSCAN_API_KEY"
echo "OPTIMISM_RPC_URL=$OPTIMISM_RPC_URL"

if [ $2 == "goerli" ]; then
  echo "Deploying to Goerli"
  forge create src/Badges.sol:Badges --private-key $DEPLOYER_PRIVATE_KEY --verify --rpc-url $GOERLI_RPC_URL --etherscan-api-key $ETHERSCAN_API_KEY
elif [ $2 == "optimism" ]; then
  echo "Deploying to Optimism"
  forge create src/Badges.sol:Badges --private-key $DEPLOYER_PRIVATE_KEY --verify --rpc-url $OPTIMISM_RPC_URL --etherscan-api-key $OPTIMISTIC_ETHERSCAN_API_KEY
fi

