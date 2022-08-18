// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.7;

import "forge-std/Test.sol";
import { IERC165 } from "./IERC165.sol";

import { IERC721Metadata } from "./IERC721Metadata.sol";
import { IERC4973 } from "ERC4973/interfaces/IERC4973.sol";
import { Badges } from "./Badges.sol";
import { SpecDataHolder } from "./SpecDataHolder.sol";
import { Raft } from "./Raft.sol";

contract SpecDataHolderTest is Test {
  Raft raft;
  Badges badges;
  SpecDataHolder specDataHolder;

  address passiveAddress = 0x0f6A79A579658E401E0B81c6dde1F2cd51d97176;
  uint256 passivePrivateKey = 0xad54bdeade5537fb0a553190159783e45d02d316a992db05cbed606d3ca36b39;
  uint256 randomPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
  string specUri;

  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  function setUp() public {
    address to = address(this);
    raft = new Raft();
    raft.initialize(to, "Raft", "RAFT");
    specUri = "some spec uri";
    badges = new Badges();

    vm.label(passiveAddress, "passive");
    specDataHolder = new SpecDataHolder();

    specDataHolder.initialize(address(raft), to);
    badges.initialize("Badges", "BADGES", "0.1.0", to, address(specDataHolder));
  }

  function createRaft() public returns (uint256) {
    address to = address(this);
    address from = address(0);

    vm.expectEmit(true, true, true, false);
    uint256 raftTokenId = raft.mint(to, "some uri");
    emit Transfer(from, to, raftTokenId);

    assertEq(raftTokenId, 1);
    assertEq(raft.balanceOf(to), 1);
    return raftTokenId;
  }

  // set Raft
  function testSetRaft() public {
    createRaft();
    address newRaftAddress = vm.addr(randomPrivateKey);
    specDataHolder.setRaft(newRaftAddress);
    assertEq(specDataHolder.getRaftAddress(), newRaftAddress);
  }

  function testSetRaftAsNonOwner() public {
    createRaft();
    address newRaftAddress = vm.addr(randomPrivateKey);
    address attacker = vm.addr(randomPrivateKey);
    vm.prank(attacker);
    vm.expectRevert(bytes("Ownable: caller is not the owner"));
    specDataHolder.setRaft(newRaftAddress);
  }

  function testGetRaft() public {
    createRaft();
    specDataHolder.getRaftAddress();
    assertEq(specDataHolder.getRaftAddress(), address(raft));
  }

  function testGetRaftTokenId() public {
    uint256 raftTokenId = createRaft();
    badges.createSpec(specUri, raftTokenId);
    assertEq(specDataHolder.specIsRegistered(specUri), true);
    assertEq(specDataHolder.getRaftTokenId(specUri), 1);
  }

  function testSetBadgesAddress() public {
    assertEq(specDataHolder.getBadgesAddress(), address(0));
    address randomAddress = vm.addr(randomPrivateKey);

    specDataHolder.setBadgesAddress(randomAddress);
    assertEq(specDataHolder.getBadgesAddress(), randomAddress);
  }

  function testSetBadgesAddressAsNonOwner() public {
    assertEq(specDataHolder.getBadgesAddress(), address(0));
    address randomAddress = vm.addr(randomPrivateKey);
    vm.prank(randomAddress);
    vm.expectRevert(bytes("Ownable: caller is not the owner"));
    specDataHolder.setBadgesAddress(randomAddress);
  }

  // setBadgeToRaft

  // specIsRegistered

  // setSpecToRaft

  // getRaftOwner

  // transfer ownership

  // transfer ownership as non-owner
}
