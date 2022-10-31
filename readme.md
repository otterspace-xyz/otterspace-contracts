# otterspace-contracts

[![unit tests](https://github.com/otterspace-xyz/otterspace-contracts/actions/workflows/main.yml/badge.svg)](https://github.com/otterspace-xyz/otterspace-contracts/actions/workflows/main.yml)

### Otterspace’s [EIP-4973](https://github.com/ethereum/EIPs/pull/4973)-compliant non-transferable badge protocol helps DAOs create better incentive systems, automate permissions and enable non-financialized governance ✨ 🦦 🚀

---

# Project setup

- Install [Foundry](https://book.getfoundry.sh/getting-started/installation.html)
- Requires Node `v16` and Solidity `0.8.16`

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

### Live contracts on Optimism:

- [Badges.sol](https://optimistic.etherscan.io/address/0x7F9279B24D1c36Fa3E517041fdb4E8788dc63D25)
- [Raft.sol](https://optimistic.etherscan.io/address/0xa6773847d3D2c8012C9cF62818b320eE278Ff722)
- [SpecDataHolder.sol](https://optimistic.etherscan.io/address/0xEE0c743A3E50133B63eDFcc0006aA331Adf1e4BC)

---

Live contracts on Goerli:

- [Badges.sol](https://goerli.etherscan.io/address/0xa6773847d3D2c8012C9cF62818b320eE278Ff722)
- [Raft.sol](https://goerli.etherscan.io/address/0xBb8997048e5F0bFe6C9D6BEe63Ede53BD0236Bb2)
- [SpecDataHolder.sol](https://goerli.etherscan.io/address/0x7F9279B24D1c36Fa3E517041fdb4E8788dc63D25)

### Use ABIs with JavaScript

We're publishing this repository at [@otterspace-xyz/contracts](https://www.npmjs.com/package/@otterspace-xyz/contracts)

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

SpecDataHolder ABI

```js
import SpecDataHolder from '@otterspace-xyz/contracts/out/SpecDataHolder.sol/SpecDataHolder.json' assert { type: 'json' }
```


We're exporting specific `.sol` files using the `"files"` property in
`package.json`. Please familiarize yourself with the `.sol` files we're
exporting by looking into `package.json`.

---

## Tech Stack

We use **Foundry** and **Hardhat** together. With this setup we get:

- Unit tests written in Solidity (Forge)
- Integration tests written in JavaScript (Mocha)

---

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- [**Forge**](https://book.getfoundry.sh/forge/): Ethereum testing framework (like Truffle, Hardhat and DappTools).
- [**Cast**](https://book.getfoundry.sh/cast/): Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- [**Anvil**](https://book.getfoundry.sh/anvil/): local Ethereum node, akin to Ganache, Hardhat Network.

**Need help getting started with Foundry? Read the [📖 Foundry Book](https://book.getfoundry.sh/)!**

### Hardhat

Hardhat is an Ethereum development environment for professionals. It facilitates performing frequent tasks, such as running tests, automatically checking code for mistakes or interacting with a smart contract.

On [Hardhat's website](https://hardhat.org) you will find:

- [Guides to get started](https://hardhat.org/getting-started/)
- [Hardhat Network](https://hardhat.org/hardhat-network/)
- [Plugin list](https://hardhat.org/plugins/)

## Deploying and verifying the contract

- create a `.env` file matching the variables seen in `.env.example`
- run `./scripts/deployProxy.ts .env`
- Hardhat will deploy the SpecDataHolder, Raft, and Badges contracts, then deploy a proxy for each one.
- Once deployed, follow the logged instructions in your terminal to verify the contracts.
- **VERY IMPORTANT**: call `setBadgesAddress` on the `SpecDataHolder` contract. Without this, it won't work.

## Foundry setup for VS Code Users

Add a `.vscode` file under the root

```json
{
  "solidity.packageDefaultDependenciesContractsDirectory": "src",
  "solidity.packageDefaultDependenciesDirectory": "lib",
  "solidity.compileUsingRemoteVersion": "v0.8.16"
}
```

## Changelog

See changelog.md file.

### Checklist for bumping version

- update "version" in package.json
- re-deploy contracts
- update contract addresses in readme (if necessary)
- update changelog

## License

See LICENSE file.
