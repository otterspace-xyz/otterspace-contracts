// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

import "forge-std/Test.sol";
import {Badges} from "./Badges.sol";

string constant name = "Name";
string constant symbol = "Symbol";
string constant version = "V1";

// contract ProxyActor {
//   function proxyMint(address collection, address to) public returns (uint256) {
//     Badges b = Badges(collection);
//     return b.mint(to);
//   }
// }

contract BadgesTest is Test {
  Badges b;
  string constant uri = "https://ipfs.io/ipfs/QmdoUaYzKCMUmeH473amYJNyFrL1a6gtccQ5rYsqqeHBsC";

  function setUp() public {
    b = new Badges(name, symbol, version);
  }

  // function testMintingWithoutAuthorization() public {
  //   ProxyActor pa = new ProxyActor();
  //   address collection = address(b);
  //   address receiver = address(1337);

  //   vm.expectRevert(bytes("Ownable: caller is not the owner"));
  //   pa.proxyMint(collection, receiver);
  // }

  // function testMintingWithTransferredAuthorization() public {
  //   ProxyActor pa = new ProxyActor();
  //   address collection = address(b);
  //   address receiver = address(1337);

  //   vm.expectRevert(bytes("Ownable: caller is not the owner"));
  //   pa.proxyMint(collection, receiver);

  //   b.transferOwnership(address(pa));
  //   uint256 tokenId = pa.proxyMint(collection, receiver);
  //   assertEq(tokenId, 0);
  // }

  // function testOwnership() public {
  //   assertEq(b.owner(), address(this));

  //   address nextOwner = address(1337);
  //   b.transferOwnership(nextOwner);
  //   assertEq(b.owner(), nextOwner);
  // }

  function testConstructorParams() public {
    assertEq(b.name(), name);
    assertEq(b.symbol(), symbol);
  }

  // function testMinting() public {
  //   address to = address(1);
  //   uint256 tokenId = b.mint(to);
  //   assertEq(tokenId, 0);
  //   assertEq(b.tokenURI(tokenId), uri);
  // }

  // function testMintingTwice() public {
  //   address to = address(1);
  //   uint256 tokenId = b.mint(to);
  //   assertEq(tokenId, 0);
  //   assertEq(b.tokenURI(tokenId), uri);
  //   uint256 tokenId1 = b.mint(to);
  //   assertEq(tokenId1, 1);
  //   assertEq(b.tokenURI(tokenId1), uri);
  // }
}
