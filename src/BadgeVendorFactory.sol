// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import {Badges} from "./Badges.sol";
import {BadgeVendor} from "./BadgeVendor.sol";

contract BadgeVendorFactory {
  event CreateBadge(
    address indexed _issuer,
    address indexed _vendor,
    address indexed _badges
  );

  function createBadge(
    address issuer,
    string memory name,
    string memory symbol
  ) external returns (address, address) {
    BadgeVendor bv = new BadgeVendor(issuer, name);
    Badges b = new Badges(name, symbol, address(bv));
    emit CreateBadge(issuer, address(bv), address(b));
    return (address(bv), address(b));
  }
}
