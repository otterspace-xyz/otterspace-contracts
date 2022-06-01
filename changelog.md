# Changelog

We're using https://semver.org/

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
