// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "forge-std/Test.sol";
import {ChainClaim} from "chain-claim/ChainClaim.sol";

import {BadgeVendor, Badges, Vendor } from "./BadgeVendor.sol";

// Reference: https://github.com/botdad/chain-claim/blob/d9bee752457e400ab3eac9988b6c7a755e7ff925/src/test/ChainClaim.t.sol#L67
contract BadgeVendorTest is Test {
  BadgeVendor bv;
  Badges badges;

  string name = "some name";
  // predetermined address for pregenerated test claim code signing
  address exAddress = 0xb07dAd0000000000000000000000000000000001;
	BadgeVendor target = BadgeVendor(exAddress);

  address issuerAddress = 0x0f6A79A579658E401E0B81c6dde1F2cd51d97176;
  uint256 issuerPkey =
    0xad54bdeade5537fb0a553190159783e45d02d316a992db05cbed606d3ca36b39;
  address claimCodeAddress = 0xB2DDDD291289EfF4715F6e84CdB3D845a93037A6;
  uint256 claimCodePkey =
    0x55b7b79aa0a71a634d00343ecb270adc0105d11566c7fcafa9381272d8d26554;

  uint8 claimCodeV;
  bytes32 claimCodeR;
  bytes32 claimCodeS;

  function setUp() public {
    Vendor memory vendor = Vendor(issuerAddress, name);
    bv = new BadgeVendor(vendor);
		vm.etch(exAddress, address(bv).code);

    // address(target) == exAddress
    badges = new Badges("name", "symbol", address(exAddress));

		(claimCodeV, claimCodeR, claimCodeS) = vm.sign(
      issuerPkey,
      target._genDataHash(claimCodeAddress)
    );
  }

  function testChainClaim() public {
    assertEq(bv.ISSUER(), issuerAddress);
  }

  function testCollectionOwnership() public {
    assertEq(badges.owner(), address(exAddress));
  }

  function testTakeBadge() public {
    bytes32 hash = target._genDataHash(address(this));
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(claimCodePkey, hash);

    address collection = address(badges);
		uint256 tokenId = target.takeBadge(
      collection,
      claimCodeAddress,
      [claimCodeV, v],
      [claimCodeR, r],
      [claimCodeS, s]
    );
		assertEq(tokenId, 0);
  }
}
