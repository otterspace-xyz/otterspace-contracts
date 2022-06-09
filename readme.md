# otterspace-contracts

[![unit tests](https://github.com/otterspace-xyz/otterspace-contracts/actions/workflows/main.yml/badge.svg)](https://github.com/otterspace-xyz/otterspace-contracts/actions/workflows/main.yml)

### An [EIP-4973](https://github.com/ethereum/EIPs/pull/4973)-compliant Account-bound token to otterify Ethereum.

## Project Information

This repository hosts the code for Otterspace Badges.

## Contracts

- [BadgeVendorFactory (Rinkeby)](https://rinkeby.etherscan.io/address/0x0ec999881841940c684438b42f648986295b5aa8)

### Use ABIs with JavaScript

We're publishing this repository at `@otterspacexyz/contracts`.

```bash
npm i @otterspacexyz/contracts
```

With node >=
16, contract ABIs can be imported into JavaScript applications as npm
dependencies as follows:

```js
import Badges from "@otterspacexyz/contracts/out/Badges.sol/Badges.json" assert { type: "json" };
```

## Developer setup

### Foundry

- This project used git submodules
- Install [Foundry](https://book.getfoundry.sh/getting-started/installation.html)

```bash
git clone git@github.com:otterspace-xyz/otterspace-contracts.git
git submodule update --init
forge install
forge build
forge test
```

#### Foundry setup for VS Code Users

Per instructions laid out at https://book.getfoundry.sh/config/vscode.html

Generate a remappings with `forge remappings` and create a remappings.txt under the root

Sample remappings.txt file

```txt
@openzeppelin/=lib/openzeppelin-contracts/
chain-claim/=lib/chain-claim/src/
forge-std/=lib/forge-std/src/
ds-test/=lib/forge-std/lib/ds-test/src/
ERC4973/=lib/ERC4973/src/
```

Add a .vscode file under the root

```json
{
  "solidity.packageDefaultDependenciesContractsDirectory": "src",
  "solidity.packageDefaultDependenciesDirectory": "lib",
  "solidity.compileUsingRemoteVersion": "v0.8.10"
}
```

### Hardhat

Alternatively, this repository is available for importing with npm/hardhat:

```bash
npm i @otterspacexyz/contracts
```

We're exporting specific `.sol` files using the `"files"` property in
`package.json`. Please familiarize yourself with the `.sol` files we're
exporting by looking into `package.json`.

## Changelog

See changelog.md file.

## License

See LICENSE file.
