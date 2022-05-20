# otterspace-contracts

[![unit tests](https://github.com/otterspace-xyz/otterspace-contracts/actions/workflows/main.yml/badge.svg)](https://github.com/otterspace-xyz/otterspace-contracts/actions/workflows/main.yml)

### An [EIP-4973](https://github.com/ethereum/EIPs/pull/4973)-compliant Account-bound token to otterify Ethereum.

## Project Information

This repository hosts the code for an
[EIP-4973](https://otterspace-xyz.github.io/badges/) demo. We've created a
front end hosted at
[https://badges.otterspace.xyz/](https://badges.otterspace.xyz/)
[[source](https://github.com/otterspace-xyz/badges)] that users can interact
with on the Rinkeby Test Network. It allows anyone with Rinkeby Ether to mint
an account-bound token to a given address with a fixed
[metadata.json](./metadata.json).

## Contracts

- Contract on Etherscan (Rinkeby):
  [rinkeby.etherscan.io/address/0x9a8469255a7d41a715e539a22eb1127be0973a1e](https://rinkeby.etherscan.io/address/0x9a8469255a7d41a715e539a22eb1127be0973a1e)
- Metadata hosted on IPFS:
  [QmdoUaYzKCMUmeH473amYJNyFrL1a6gtccQ5rYsqqeHBsC](https://ipfs.io/ipfs/QmdoUaYzKCMUmeH473amYJNyFrL1a6gtccQ5rYsqqeHBsC)

## Developer setup
* This project used git submodules
* Install [Foundry](https://book.getfoundry.sh/getting-started/installation.html)
```bash
git submodule update --init
forge install
forge build
forge test
```

## Contributing

```bash
git clone git@github.com:otterspace-xyz/otterspace-contracts.git
forge test
```

## Changelog

#### 0.0.1

- Initial deployment of https://badges.otterspace.xyz

## License

See LICENSE file.
