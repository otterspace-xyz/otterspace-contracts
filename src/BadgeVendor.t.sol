// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {ERC4973Permit} from "ERC4973/ERC4973Permit.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import {BadgeVendor} from "./BadgeVendor.sol";
import {Badges} from "./Badges.sol";

string constant rompNFTBaseURI = "https://nftapi.com/";

contract MockRompNFT is ERC721 {
  constructor() ERC721("name", "symbol") {
  }

  function _baseURI() internal pure override returns (string memory) {
    return rompNFTBaseURI;
  }

  function mint(address to, uint256 tokenId) public {
    return super._mint(to, tokenId);
  }
}

contract MockVendor is ERC4973Permit {
  constructor() ERC4973Permit("name", "symbol", "version") {}

  function getHash(
    address from,
    address to,
    string calldata tokenURI
  ) external view returns (bytes32) {
    return super._getHash(from, to, tokenURI);
  }
}

// Reference: https://github.com/botdad/chain-claim/blob/d9bee752457e400ab3eac9988b6c7a755e7ff925/src/test/ChainClaim.t.sol#L67
contract BadgeVendorTest is Test {
  Badges badges;
  BadgeVendor bv;

  MockRompNFT romp;
  MockVendor mv;

  string name = "some name";
  uint256 rompTokenId = 100;
  string specUri = "ipfs://spec_uri";

  // predetermined address for pregenerated test claim code signing
  address exAddress = 0xb07dAd0000000000000000000000000000000001;
	BadgeVendor target = BadgeVendor(exAddress);

  address fromAddress = 0x0f6A79A579658E401E0B81c6dde1F2cd51d97176;
  uint256 fromPrivateKey = 0xad54bdeade5537fb0a553190159783e45d02d316a992db05cbed606d3ca36b39;

  address toAddress = 0xB2DDDD291289EfF4715F6e84CdB3D845a93037A6;
  uint256 toPrivateKey = 0x55b7b79aa0a71a634d00343ecb270adc0105d11566c7fcafa9381272d8d26554;

  function setUp() public {
    romp = new MockRompNFT();
    badges = new Badges("name", "symbol", "version");
    bv = new BadgeVendor(address(romp), address(badges));
    mv = new MockVendor();

    romp.mint(fromAddress, rompTokenId);

		vm.etch(exAddress, address(bv).code);
  }

  function testCreateBadgeSpec() public {
    // vm.expectEmit(true, false, false, false);
    vm.prank(fromAddress);
    bv.createBadgeSpec(rompTokenId, specUri);
    assertEq(bv.ownerOfSpec(specUri), rompTokenId);
  }

  function testClaimBadge() public {
    vm.prank(fromAddress);
    bv.createBadgeSpec(rompTokenId, specUri);
    console.log(bv.ownerOfSpec(specUri));

    bytes32 hash = mv.getHash(fromAddress, toAddress, specUri);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(fromPrivateKey, hash);

    vm.prank(toAddress);
		uint256 tokenId = bv.claimBadge(
      fromAddress,
      specUri,
      v,
      r,
      s
    );

		assertEq(tokenId, 0);
  }
}
