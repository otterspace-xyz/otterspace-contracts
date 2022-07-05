// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {Badges} from "../src/Badges.sol";
import {ERC4973Permit} from "ERC4973/ERC4973Permit.sol";

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



contract BadgesTest is Test {
  Badges b;
  MockBadges mb;

  string constant name = "Name";
  string constant symbol = "Symbol";
  string constant version = "V1";

  address fromAddress = 0x0f6A79A579658E401E0B81c6dde1F2cd51d97176;
  uint256 fromPrivateKey = 0xad54bdeade5537fb0a553190159783e45d02d316a992db05cbed606d3ca36b39;

  address toAddress = 0xB2DDDD291289EfF4715F6e84CdB3D845a93037A6;
  uint256 toPrivateKey = 0x55b7b79aa0a71a634d00343ecb270adc0105d11566c7fcafa9381272d8d26554;

  function setUp() public {
    b = new Badges(name, symbol, version);
    mb = new MockBadges();
  }

  function testConstructorParams() public {
    assertEq(b.name(), name);
    assertEq(b.symbol(), symbol);
  }

  function testMintWithPermission() public {
    string memory tokenURI = "https://some-token-uri.com";
    bytes32 hash = mb.getHash(fromAddress, toAddress, tokenURI);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(fromPrivateKey, hash);

    vm.prank(toAddress);
    bytes memory signature = abi.encodePacked(r, s, v);
		uint256 tokenId = mb.mintWithPermission(fromAddress, tokenURI, signature);

		assertEq(tokenId, 0);
  }

    function testName() public {
        assertEq(b.name(), "Name");
    }
}
