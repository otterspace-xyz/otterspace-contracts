# Changelog

We're using https://semver.org/

## 2.0.0

- Refactor SpecDataHolder and Badges to use interfaces instead of importing whole contracts
- uncomment constructor in Badges
- improve consistency with variable naming

- Live contracts on **Optimism**
- - [Badges.sol](https://optimistic.etherscan.io/address/0x7F9279B24D1c36Fa3E517041fdb4E8788dc63D25)
- - [Raft.sol](https://optimistic.etherscan.io/address/0xa74caa864a2562999faf38280a3aa3d09c248daa)
- - [SpecDataHolder.sol](https://optimistic.etherscan.io/address/0xEE0c743A3E50133B63eDFcc0006aA331Adf1e4BC)

- Live contracts on **Goerli**
- - [Badges.sol](https://goerli.etherscan.io/address/0xa6773847d3D2c8012C9cF62818b320eE278Ff722)
- - [Raft.sol](https://goerli.etherscan.io/address/0xe620d9CACA4C2B02601C08095a0d5aA14C59270E)
- - [SpecDataHolder.sol](https://goerli.etherscan.io/address/0x7F9279B24D1c36Fa3E517041fdb4E8788dc63D25)

## 1.0.1

- Added `/out/Raft.sol/Raft.json` to repo
- Live contracts on Optimism
- Live contracts on **Optimism**
- - [Badges.sol](https://optimistic.etherscan.io/address/0x639a1703CfdeDaE61A535d53890130b4257f15eb)
- - [Raft.sol](https://optimistic.etherscan.io/address/0xa74caa864A2562999faf38280A3aA3d09c248daA)
- - [SpecDataHolder.sol](https://optimistic.etherscan.io/address/0xdB8346EAF8C4A7eF82B17Ce7843dF8A9d00dC524)

## 1.0.0

- Initial release on Optimism
- Contracts upgradeable using [UUPS pattern](https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable)
- Add unit tests with Forge
- Fix security vulnerabilites
- Live contracts on **Optimism**
- - [Badges.sol](https://optimistic.etherscan.io/address/0x639a1703CfdeDaE61A535d53890130b4257f15eb)
- - [Raft.sol](https://optimistic.etherscan.io/address/0xa74caa864a2562999faf38280a3aa3d09c248daa)
- - [SpecDataHolder.sol](https://optimistic.etherscan.io/address/0xdB8346EAF8C4A7eF82B17Ce7843dF8A9d00dC524)
- Live contracts on **Goerli**
- - [Badges.sol](https://goerli.etherscan.io/address/0x835bD6b20206417ff9168B174cE67D812D746dc5)
- - [Raft.sol](https://goerli.etherscan.io/address/0xe620d9CACA4C2B02601C08095a0d5aA14C59270E)
- - [SpecDataHolder.sol](https://goerli.etherscan.io/address/0x147e0dF40fdD1340C604726c670329c08176F208)

## 0.6.0

- Make contracts upgradeable
- Seprate spec-related data to SpecDataHolder
- Move logic of ERC-4973 into Badges.sol (ERC-4973 is no longer a dependency)
- Move deployments over to Goerli
- Badges Goerli deployment: https://goerli.etherscan.io/address/0xde30567ebA075D622da01D0836aFcc4356dB9dEC
- Raft Goerli deployment: https://goerli.etherscan.io/address/0xA32Ef0ED6B60dD406f37f31D40044AD8F6530bbe
- SpecDataHolder Goerli deployment: https://goerli.etherscan.io/address/0x562AD9882B50AB12C445c5b0e30acBE02c09b7F9

## 0.5.0

- Add Raft token
- Add Rinkeby deployment/verification scripts for Badges and Raft token
- Improve integration tests
- Badges Rinkeby deployment: https://rinkeby.etherscan.io/address/0x9323497dc6f24df13fcd09d71bb17efa47b659e3
- Rinkeby deployment: https://rinkeby.etherscan.io/address/0x19020014ef77c5dce4fbcf97c2e3d6e67a616fc6

## 0.4.0

- Introduced Hardhat support
- Using Solidity 0.8.15
- Using Yarn instead of npm
- Rinkeby deployment: https://rinkeby.etherscan.io/address/0x19020014ef77c5dce4fbcf97c2e3d6e67a616fc6

## 0.3.0

- Replacing `Chain-Claim` with ` mintWithPermission`` from  `ERC4973Permit`
- `BadgeVendorFactory` and `BadgeVendor` are no longer existing in this version

## 0.2.0

- Added `BadgeVendorFactory` and deployed to Rinkeby
- (breaking) In `BadgeVendor` constructor use simple primitive types instead of
  struct.

## 0.1.1

Publishing now to @otterspace-xyz org.

## 0.1.0

First release that makes contracts available on npm. It allows, e.g. importing
the contract ABI as follows:

```nodejs
import Badges from "@otterspacexyz/contracts/out/Badges.sol/Badges.json" assert { type: "json" };
```

We mark this release as **breaking** as the contract structure very much
changed. Now, a `BadgeVendor.issuer` has to sign messages that can be used to
call `Badges.mint`.

## 0.0.1

- Initial release on mainnet
