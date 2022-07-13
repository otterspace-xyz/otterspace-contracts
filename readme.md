# otterspace-contracts

[![unit tests](https://github.com/otterspace-xyz/otterspace-contracts/actions/workflows/main.yml/badge.svg)](https://github.com/otterspace-xyz/otterspace-contracts/actions/workflows/main.yml)

### An [EIP-4973](https://github.com/ethereum/EIPs/pull/4973)-compliant Account-bound token to otterify Ethereum.

## Project Information

This repository hosts the code for Otterspace Badges.

### Use ABIs with JavaScript

We're publishing this repository at `@otterspace-xyz/contracts`.

```bash
npm i @otterspace-xyz/contracts
```

With node >= 16, contract ABIs can be imported into JavaScript applications as npm dependencies as follows:

```js
import Badges from '@otterspace-xyz/contracts/out/Badges.sol/Badges.json' assert { type: 'json' }
```

## Tech Stack

We use **Foundry** and **Hardhat** together. With this setup we get:

-   Unit tests written in Solidity
-   Integration tests written in JavaScript

### Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   [**Forge**](./forge): Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   [**Cast**](./cast): Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   [**Anvil**](./anvil): local Ethereum node, akin to Ganache, Hardhat Network.

**Need help getting started with Foundry? Read the [📖 Foundry Book][foundry-book] (WIP)!**

### Hardhat

Hardhat is an Ethereum development environment for professionals. It facilitates performing frequent tasks, such as running tests, automatically checking code for mistakes or interacting with a smart contract.

On [Hardhat's website](https://hardhat.org) you will find:

-   [Guides to get started](https://hardhat.org/getting-started/)
-   [Hardhat Network](https://hardhat.org/hardhat-network/)
-   [Plugin list](https://hardhat.org/plugins/)

## Project setup

-   Install [Foundry](https://book.getfoundry.sh/getting-started/installation.html)
-   Requires Node `v16` and Solidity `0.8.15`

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

### Deploying and verifying contract

-   create an `.env.network` file matching the variables seen in `.env.example`
-   run `./scripts/deploy_and_verify.sh .env.network`
-   Forge will build, verify, and confirm verification

#### Foundry setup for VS Code Users

Add a .vscode file under the root

```json
{
    "solidity.packageDefaultDependenciesContractsDirectory": "src",
    "solidity.packageDefaultDependenciesDirectory": "lib",
    "solidity.compileUsingRemoteVersion": "v0.8.15"
}
```

### Hardhat without Foundry

Alternatively, this repository is available for importing with npm/hardhat:

```bash
npm i @otterspacexyz/contracts
```

We recommend running Hardhat using the current LTS Node.js version. You can learn about it [here:](https://nodejs.org/en/about/releases/)

We're exporting specific `.sol` files using the `"files"` property in
`package.json`. Please familiarize yourself with the `.sol` files we're
exporting by looking into `package.json`.

## Changelog

See changelog.md file.

## License

See LICENSE file.
