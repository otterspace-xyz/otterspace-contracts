// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import { ChainClaim } from "chain-claim/ChainClaim.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract BadgeVendor is Ownable, ChainClaim {
  constructor(
    address nextOwner,
    string memory name
  ) ChainClaim(nextOwner, name) {
    transferOwnership(nextOwner);
  }
}
