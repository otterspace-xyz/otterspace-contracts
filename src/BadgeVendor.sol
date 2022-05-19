// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import { Badges } from "./Badges.sol";
import { ChainClaim } from "chain-claim/ChainClaim.sol";

struct Vendor {
  address issuer;
  string name;
}

struct Collection {
  string name;
  string symbol;
}

contract BadgeVendor is ChainClaim {
  Badges public badges;
  constructor(
    Vendor memory v,
    Collection memory c
  ) ChainClaim(v.issuer, v.name) {
    badges = new Badges(c.name, c.symbol, address(this));
  }
}
