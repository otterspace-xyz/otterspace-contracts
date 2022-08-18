#!/usr/bin/env bash
source $1
echo $ETH_GOERLI_URL
echo $PRIVATE_KEY_1
echo $ETHERSCAN_API_KEY

# To deploy and verify our contract
forge script script/Raft.s.sol:DeployUUPS --rpc-url $ETH_GOERLI_URL  --private-key $PRIVATE_KEY_1 --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY -vvvv
