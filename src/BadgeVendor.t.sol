// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "forge-std/Test.sol";
import {ERC4973Permit} from "ERC4973/ERC4973Permit.sol";

import {BadgeVendor} from "./BadgeVendor.sol";
import {Badges} from "./Badges.sol";

contract MockBadges is ERC4973Permit {
  constructor() ERC4973Permit("name", "symbol", "version") {}

  function getHash(
    address from,
    address to,
    string calldata tokenURI
  ) external view returns (bytes32) {
    return _getHash(from, to, tokenURI);
  }
}

// Reference: https://github.com/botdad/chain-claim/blob/d9bee752457e400ab3eac9988b6c7a755e7ff925/src/test/ChainClaim.t.sol#L67
contract BadgeVendorTest is Test {
  Badges badges;
  BadgeVendor bv;
  MockBadges mb;

  // predetermined address for pregenerated test claim code signing
  // address exAddress = 0xb07dAd0000000000000000000000000000000001;
	// BadgeVendor target = BadgeVendor(exAddress);

  address fromAddress = 0x0f6A79A579658E401E0B81c6dde1F2cd51d97176;
  uint256 fromPrivateKey = 0xad54bdeade5537fb0a553190159783e45d02d316a992db05cbed606d3ca36b39;

  address toAddress = 0xB2DDDD291289EfF4715F6e84CdB3D845a93037A6;
  uint256 toPrivateKey = 0x55b7b79aa0a71a634d00343ecb270adc0105d11566c7fcafa9381272d8d26554;

  function setUp() public {
    badges = new Badges("name", "symbol", "version");
    bv = new BadgeVendor(address(badges));

    mb = new MockBadges();

		// vm.etch(exAddress, address(bv).code);
  }

  function testClaimBadge() public {
    string memory tokenURI = "https://some-token-uri.com";
    bytes32 hash = mb.getHash(fromAddress, toAddress, tokenURI);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(fromPrivateKey, hash);

    vm.prank(toAddress);
		uint256 tokenId = bv.claimBadge(
      fromAddress,
      tokenURI,
      v,
      r,
      s
    );

		assertEq(tokenId, 0);
  }
}
