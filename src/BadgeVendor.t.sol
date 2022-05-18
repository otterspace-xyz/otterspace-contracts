// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import {DSTest} from "ds-test/test.sol";
import {BadgeVendor} from "./BadgeVendor.sol";

contract BadgeVendorTest is DSTest {
  BadgeVendor bv;

  function setUp() public {
    address owner = address(this);
    string memory name = "name";
    bv = new BadgeVendor(owner, name);
  }

  function testParameters() public {
    assertEq(bv.owner(), address(this));
  }
}
