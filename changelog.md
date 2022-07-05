# Changelog

We're using https://semver.org/

## 0.4.0

-   Introduced Hardhat support
-   Using Solidity 0.8.15
-   Using Yarn instead of npm

## 0.3.0

-   Replacing `Chain-Claim` with ` mintWithPermission`` from  `ERC4973Permit`
-   `BadgeVendorFactory` and `BadgeVendor` are no longer existing in this version

## 0.2.0

-   Added `BadgeVendorFactory` and deployed to Rinkeby
-   (breaking) In `BadgeVendor` constructor use simple primitive types instead of
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

-   Initial release on mainnet
