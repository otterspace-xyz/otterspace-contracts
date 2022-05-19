// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

import {DSTest} from "ds-test/test.sol";
import {Badges, uri} from "./Badges.sol";

string constant name = "Name";
string constant symbol = "Symbol";

contract BadgesTest is DSTest {
  Badges b;

  function setUp() public {
    b = new Badges(name, symbol);
  }

  function testNameAndSymbol() public {
    assertEq(b.name(), name);
    assertEq(b.symbol(), symbol);
  }

  function testMinting() public {
    address to = address(1);
    uint256 tokenId = b.mint(to);
    assertEq(tokenId, 0);
    assertEq(b.tokenURI(tokenId), uri);
  }
  function testMintingTwice() public {
    address to = address(1);
    uint256 tokenId = b.mint(to);
    assertEq(tokenId, 0);
    assertEq(b.tokenURI(tokenId), uri);
    uint256 tokenId1 = b.mint(to);
    assertEq(tokenId1, 1);
    assertEq(b.tokenURI(tokenId1), uri);
  }
}
