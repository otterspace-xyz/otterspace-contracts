# otterspace-contracts

[![unit tests](https://github.com/otterspace-xyz/otterspace-contracts/actions/workflows/main.yml/badge.svg)](https://github.com/otterspace-xyz/otterspace-contracts/actions/workflows/main.yml)

### Otterspace’s [EIP-4973](https://github.com/ethereum/EIPs/pull/4973)-compliant non-transferable badge protocol helps DAOs create better incentive systems, automate permissions and enable non-financialized governance ✨ 🦦 🚀

---

# Project setup

- Install [Foundry](https://book.getfoundry.sh/getting-started/installation.html)
- Requires Node `v16` and Solidity `0.8.7`

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

- [Badges.sol](https://optimistic.etherscan.io/address/0x639a1703CfdeDaE61A535d53890130b4257f15eb)
- [Raft.sol](https://optimistic.etherscan.io/address/0xa74caa864a2562999faf38280a3aa3d09c248daa)
- [SpecDataHolder.sol](https://optimistic.etherscan.io/address/0xdB8346EAF8C4A7eF82B17Ce7843dF8A9d00dC524)

---

Live contracts on Goerli:

- [Badges.sol](https://goerli.etherscan.io/address/0x835bD6b20206417ff9168B174cE67D812D746dc5)
- [Raft.sol](https://goerli.etherscan.io/address/0xe620d9CACA4C2B02601C08095a0d5aA14C59270E)
- [SpecDataHolder.sol](https://goerli.etherscan.io/address/0x147e0dF40fdD1340C604726c670329c08176F208)

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
  "solidity.compileUsingRemoteVersion": "v0.8.7"
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
