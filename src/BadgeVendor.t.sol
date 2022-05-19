// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import {DSTest} from "ds-test/test.sol";
import {BadgeVendor} from "./BadgeVendor.sol";

contract BadgeVendorTest is DSTest {
  BadgeVendor bv;

  function setUp() public {
    address issuer = address(this);
    string memory name = "name";
    bv = new BadgeVendor(issuer, name);
  }

  function testParameters() public {
    assertEq(bv.ISSUER(), address(this));
  }
}