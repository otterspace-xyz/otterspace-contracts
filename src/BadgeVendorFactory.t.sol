// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "forge-std/Test.sol";

import {BadgeVendorFactory} from "./BadgeVendorFactory.sol";

contract BadgeVendorTest is Test {
  BadgeVendorFactory bvf;

  function setUp() public {
    bvf = new BadgeVendorFactory();
  }

  function testCreateBadge() public {
    address issuer = address(1337);
    string memory name = "name";
    string memory symbol = "symbol";
    (address badgeVendor, address badges) = bvf.createBadge(issuer, name, symbol);
    assertFalse(badgeVendor == address(0));
    assertFalse(badges == address(0));
  }
}
