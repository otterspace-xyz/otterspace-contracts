// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import {Test} from "forge-std/Test.sol";
import {BadgeVendor, Vendor, Collection} from "./BadgeVendor.sol";

contract BadgeVendorTest is Test {
  BadgeVendor bv;

  function setUp() public {
    address issuer = address(this);
    Vendor memory vendor = Vendor(issuer, "name");

    string memory name = "Name";
    string memory symbol = "Symbol";
    Collection memory coll = Collection(name, symbol);

    bv = new BadgeVendor(vendor, coll);
  }

  function testChainClaim() public {
    assertEq(bv.ISSUER(), address(this));
  }

  function testCollectionOwnership() public {
    assertEq(bv.badges().owner(), address(bv));
  }
}
