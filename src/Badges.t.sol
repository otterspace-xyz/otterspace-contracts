// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

import {DSTest} from "ds-test/test.sol";
import {Badges} from "./Badges.sol";

contract BadgesTest is DSTest {
  Badges b;

  function setUp() public {
    b = new Badges();
  }

  function testMinting() public {
    address to = address(1);
    uint256 tokenId = b.mint(to);
    assertEq(tokenId, 0);
  }
  function testMintingTwice() public {
    address to = address(1);
    uint256 tokenId = b.mint(to);
    assertEq(tokenId, 0);
    uint256 tokenId1 = b.mint(to);
    assertEq(tokenId1, 1);
  }
}
