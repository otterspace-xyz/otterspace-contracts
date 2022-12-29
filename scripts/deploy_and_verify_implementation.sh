#!/usr/bin/env bash

# call this script like this:
# ./scripts/deploy_and_verify_badges.sh .env.badges goerli

# $1: the name of the .env file to use
source $1

echo "1: $1"
echo "2: $2"
echo "3: $3"
echo "DEPLOYER_PRIVATE_KEY=$DEPLOYER_PRIVATE_KEY"

if [ "$3" == "goerli" ]; then
  echo " "
  echo "GOERLI_RPC_URL=$GOERLI_RPC_URL"
  echo "ETHERSCAN_API_KEY=$ETHERSCAN_API_KEY"
  implementation=$(forge create src/$2.sol:$2 --verify --private-key $DEPLOYER_PRIVATE_KEY --rpc-url $GOERLI_RPC_URL --etherscan-api-key $ETHERSCAN_API_KEY | grep "Deployed to:" | cut -d " " -f 3)
  echo "implementation= $implementation"
  # forge verify-contract
elif [ "$3" == "optimism" ]; then
  echo " "
  echo "OPTIMISTIC_ETHERSCAN_API_KEY=$OPTIMISTIC_ETHERSCAN_API_KEY"
  echo "OPTIMISM_RPC_URL=$OPTIMISM_RPC_URL"
  forge create src/$2.sol:$2 --private-key $DEPLOYER_PRIVATE_KEY --verify --rpc-url $OPTIMISM_RPC_URL --etherscan-api-key $OPTIMISTIC_ETHERSCAN_API_KEY
fi
