# otterspace-contracts

[![unit tests](https://github.com/otterspace-xyz/otterspace-contracts/actions/workflows/main.yml/badge.svg)](https://github.com/otterspace-xyz/otterspace-contracts/actions/workflows/main.yml)

### An [EIP-4973](https://github.com/ethereum/EIPs/pull/4973)-compliant Account-bound token to otterify Ethereum.

---

## Project Information

This repository hosts the code for Otterspace Badges and the Otterspace RAFT NFT.

---

# Project setup

- Install [Foundry](https://book.getfoundry.sh/getting-started/installation.html)
- Requires Node `v16` and Solidity `0.8.15`

```bash
git clone git@github.com:otterspace-xyz/otterspace-contracts.git
git submodule update --init
yarn
forge install
forge build
forge test
npx hardhat typechain
npx hardhat test
```

Live contract on:

- [Badges contract on Goerli](https://goerli.etherscan.io/address/0xABcc616572C623ec77284b5A6bc45E169AF4bf7B)
- [Raft contract on Goerli](https://goerli.etherscan.io/address/0xe620d9CACA4C2B02601C08095a0d5aA14C59270E)
- [SpecDataHolder contract on Goerli](https://goerli.etherscan.io/address/0xFF57347602c5aD85B0A478317b5B40426b76f059)

### Use ABIs with JavaScript

We're publishing this repository at `@otterspace-xyz/contracts`.

```bash
npm i @otterspace-xyz/contracts
```

With node >= 16, contract ABIs can be imported into JavaScript applications as npm dependencies as follows:

Badges ABI

```js
import Badges from '@otterspace-xyz/contracts/out/Badges.sol/Badges.json' assert { type: 'json' }
```

Raft ABI

```js
import Raft from '@otterspace-xyz/contracts/out/Raft.sol/Raft.json' assert { type: 'json' }
```

---

## Tech Stack

We use **Foundry** and **Hardhat** together. With this setup we get:

- Unit tests written in Solidity
- Integration tests written in JavaScript

---

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- [**Forge**](https://book.getfoundry.sh/forge/): Ethereum testing framework (like Truffle, Hardhat and DappTools).
- [**Cast**](https://book.getfoundry.sh/cast/): Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- [**Anvil**](https://book.getfoundry.sh/anvil/): local Ethereum node, akin to Ganache, Hardhat Network.

**Need help getting started with Foundry? Read the [📖 Foundry Book][foundry-book] (WIP)!**

### Hardhat

Hardhat is an Ethereum development environment for professionals. It facilitates performing frequent tasks, such as running tests, automatically checking code for mistakes or interacting with a smart contract.

On [Hardhat's website](https://hardhat.org) you will find:

- [Guides to get started](https://hardhat.org/getting-started/)
- [Hardhat Network](https://hardhat.org/hardhat-network/)
- [Plugin list](https://hardhat.org/plugins/)

## Deploying and verifying the contract

- create an `.env.network.contractName` file matching the variables seen in `.env.network.contract.example`
- run `./scripts/deploy_and_verify.sh .env.network.contract`
- Forge will build, verify, and confirm verification

#### Foundry setup for VS Code Users

Add a .vscode file under the root

```json
{
  "solidity.packageDefaultDependenciesContractsDirectory": "src",
  "solidity.packageDefaultDependenciesDirectory": "lib",
  "solidity.compileUsingRemoteVersion": "v0.8.15"
}
```

## Hardhat without Foundry

Alternatively, this repository is available for importing with npm/hardhat:

```bash
npm i @otterspacexyz/contracts
```

We're exporting specific `.sol` files using the `"files"` property in
`package.json`. Please familiarize yourself with the `.sol` files we're
exporting by looking into `package.json`.

## Changelog

See changelog.md file.

### Checklist for bumping version

- update "version" in package.json
- re-deploy contracts
- update contract addresses in readme (if necessary)
- update changelog

## License

See LICENSE file.
