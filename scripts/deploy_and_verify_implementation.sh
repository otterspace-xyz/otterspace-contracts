#!/usr/bin/env bash

# call this script like this:
# ./scripts/deploy_and_verify_badges.sh .env.implementation goerli

# $1: the name of the .env file to use
source $1

echo "Deploying $2 to $3"

if [ $3 == "goerli" ]; then
  echo " "
  echo "GOERLI_RPC_URL=$GOERLI_RPC_URL"
  echo "ETHERSCAN_API_KEY=$ETHERSCAN_API_KEY"
  forge create src/$2.sol:$2 --private-key $DEPLOYER_PRIVATE_KEY --verify --rpc-url $GOERLI_RPC_URL --etherscan-api-key $ETHERSCAN_API_KEY
elif [ $3 == "sepolia" ]; then
  echo " "
  echo "SEPOLIA_RPC_URL=$SEPOLIA_RPC_URL"
  echo "ETHERSCAN_API_KEY=$ETHERSCAN_API_KEY"
  forge create src/$2.sol:$2 --private-key $DEPLOYER_PRIVATE_KEY --verify --rpc-url $SEPOLIA_RPC_URL --etherscan-api-key $ETHERSCAN_API_KEY
elif [ $3 == "polygon" ]; then
  echo " "
  echo "POLYGON_RPC_URL=$POLYGON_RPC_URL"
  echo "POLYGON_ETHERSCAN_API_KEY=$POLYGON_ETHERSCAN_API_KEY"
  forge create src/$2.sol:$2 --private-key $DEPLOYER_PRIVATE_KEY --verify --rpc-url $POLYGON_RPC_URL --etherscan-api-key $POLYGON_ETHERSCAN_API_KEY
elif [ $3 == "optimism-goerli" ]; then
  echo " "
  echo "OPTIMISM_GOERLI_RPC_URL=$OPTIMISM_GOERLI_RPC_URL"
  echo "OPTIMISTIC_ETHERSCAN_API_KEY=$OPTIMISTIC_ETHERSCAN_API_KEY"
  forge create src/$2.sol:$2 --private-key $DEPLOYER_PRIVATE_KEY --verify --rpc-url $OPTIMISM_GOERLI_RPC_URL --etherscan-api-key $OPTIMISTIC_ETHERSCAN_API_KEY
elif [ $3 == "optimism" ]; then
  echo " "
  echo "OPTIMISTIC_ETHERSCAN_API_KEY=$OPTIMISTIC_ETHERSCAN_API_KEY"
  echo "OPTIMISM_RPC_URL=$OPTIMISM_RPC_URL"
  forge create src/$2.sol:$2 --private-key $DEPLOYER_PRIVATE_KEY --verify --rpc-url $OPTIMISM_RPC_URL --etherscan-api-key $OPTIMISTIC_ETHERSCAN_API_KEY
fi
