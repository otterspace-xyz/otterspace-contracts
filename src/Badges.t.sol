// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

import {DSTest} from "ds-test/test.sol";
import {Badges, uri} from "./Badges.sol";

string constant name = "Name";
string constant symbol = "Symbol";

contract ProxyActor {
  function proxyMint(address collection, address to) public returns (uint256) {
    Badges b = Badges(collection);
    return b.mint(to);
  }

}

contract BadgesTest is DSTest {
  Badges b;

  function setUp() public {
    address owner = address(this);
    b = new Badges(name, symbol, owner);
  }

  function testMintingAuthorization() public {
    ProxyActor pa = new ProxyActor();
    address collection = address(b);
    address receiver = address(1337);

    uint256 tokenId = pa.proxyMint(collection, receiver);
  }

  function testOwnership() public {
    assertEq(b.owner(), address(this));

    address nextOwner = address(1337);
    b.transferOwnership(nextOwner);
    assertEq(b.owner(), nextOwner);
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
