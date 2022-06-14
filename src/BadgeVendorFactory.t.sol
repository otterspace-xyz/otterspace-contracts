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
    // NOTE: To allow reproducing this integration tests in other languages like
    // JavaScript, we're explicitly asserting string values in the following test.
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
    assertEq(claimCodeAddress, 0xB2DDDD291289EfF4715F6e84CdB3D845a93037A6);
    assertEq(bv._genDataHash(claimCodeAddress), 0x6e88f750bf52988e1b64899bff25a187e5354b20a01c21bc6816b066bd8c3e03);
    assertEq(issuerCodeV, 28);
    assertEq(issuerCodeR, 0xfb1b9506e09bd873fa54eb0e89002b9178e5942a61e0f7323f0e78aad3a003b1);
    assertEq(issuerCodeS, 0x166954335164cc60cfbca7dc3fa5a61796e146f97c50fae30a9e119286b3221c);
    (
      uint8 claimCodeV,
      bytes32 claimCodeR,
      bytes32 claimCodeS
    ) = vm.sign(claimCodePkey, bv._genDataHash(address(this)));

    assertEq(address(this), 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84);
    assertEq(bv._genDataHash(address(this)), 0x7ea1d43c66c52d2b72c06c8c4a3bc2701a5c922d34892eb512decaaa8225c7dc);
    assertEq(claimCodeV, 27);
    assertEq(claimCodeR, 0xc855ca5e5c5813ec4a0883f14e133a889d011b2115699333bdfc11568261a846);
    assertEq(claimCodeS, 0x57ccdd1e9d129ba35a0c227d153fe479ed041b126938ea156d1ec56818b1ff62);

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
