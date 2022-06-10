// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "forge-std/Test.sol";

import {Badges} from "./Badges.sol";
import {BadgeVendor} from "./BadgeVendor.sol";
import {BadgeVendorFactory} from "./BadgeVendorFactory.sol";

contract BadgeVendorTest is Test {
  BadgeVendorFactory bvf;
  address issuerAddress = 0x0f6A79A579658E401E0B81c6dde1F2cd51d97176;
  uint256 issuerPkey =
    0xad54bdeade5537fb0a553190159783e45d02d316a992db05cbed606d3ca36b39;
  address claimCodeAddress = 0xB2DDDD291289EfF4715F6e84CdB3D845a93037A6;
  uint256 claimCodePkey =
    0x55b7b79aa0a71a634d00343ecb270adc0105d11566c7fcafa9381272d8d26554;

  function setUp() public {
    bvf = new BadgeVendorFactory();
  }

  function testCreateBadge() public {
    string memory name = "name";
    string memory symbol = "symbol";
    (address badgeVendor, address badges) = bvf.createBadge(issuerAddress, name, symbol);
    assertFalse(badgeVendor == address(0));
    assertFalse(badges == address(0));
  }

  function testMintBadgeAsIntegration() public {
    string memory name = "name";
    string memory symbol = "symbol";
    (address badgeVendor, address badges) = bvf.createBadge(issuerAddress, name, symbol);
    Badges b = Badges(badges);
    BadgeVendor bv = BadgeVendor(badgeVendor);
    assertEq(b.owner(), badgeVendor);
    assertEq(bv.ISSUER(), issuerAddress);

    (
      uint8 issuerCodeV,
      bytes32 issuerCodeR,
      bytes32 issuerCodeS
    ) = vm.sign(issuerPkey, bv._genDataHash(claimCodeAddress));
    (
      uint8 claimCodeV,
      bytes32 claimCodeR,
      bytes32 claimCodeS
    ) = vm.sign(claimCodePkey, bv._genDataHash(address(this)));

		uint256 tokenId = bv.takeBadge(
      badges,
      claimCodeAddress,
      [issuerCodeV, claimCodeV],
      [issuerCodeR, claimCodeR],
      [issuerCodeS, claimCodeS]
    );
		assertEq(tokenId, 0);
  }
}
