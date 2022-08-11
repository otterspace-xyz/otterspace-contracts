// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

import "forge-std/Test.sol";
import { IERC165 } from "./IERC165.sol";

import { IERC721Metadata } from "./IERC721Metadata.sol";
import { IERC4973 } from "ERC4973/interfaces/IERC4973.sol";
import { Badges } from "./Badges.sol";
import { SpecDataHolder } from "./SpecDataHolder.sol";
import { Raft } from "./Raft.sol";

contract RaftTest is Test {
  Raft raft;

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

    vm.label(passiveAddress, "passive");
  }

  function testMintRaft() public {
    address to = address(this);
    address from = address(0);

    vm.expectEmit(true, true, true, false);
    uint256 raftTokenId = raft.mint(to, "some uri");
    emit Transfer(from, to, raftTokenId);

    assertEq(raftTokenId, 1);
    assertEq(raft.balanceOf(to), 1);
  }

  function testMintRaftAsNonOwnerWhilePaused() public {
    address to = address(this);
    bool paused = raft.paused();
    assertEq(paused, true);
    address attacker = vm.addr(randomPrivateKey);
    vm.prank(attacker);
    vm.expectRevert(bytes("mint: unauthorized to mint"));
    raft.mint(to, "some uri");
  }

  function testUnpauseTheContract() public {
    assertEq(raft.paused(), true);
    raft.unpause();
    assertEq(raft.paused(), false);
  }

  function testUnpauseTheContractAsAttacker() public {
    bool paused = raft.paused();
    assertEq(paused, true);
    address attacker = vm.addr(randomPrivateKey);
    vm.prank(attacker);
    vm.expectRevert(bytes("Ownable: caller is not the owner"));
    raft.unpause();
  }

  function testSetTokenURI() public {
    address to = address(this);
    address from = address(0);

    vm.expectEmit(true, true, true, false);
    uint256 raftTokenId = raft.mint(to, "some uri");
    emit Transfer(from, to, raftTokenId);

    assertEq(raftTokenId, 1);
    assertEq(raft.balanceOf(to), 1);
    raft.setTokenURI(raftTokenId, "some new uri");
    assertEq(raft.tokenURI(raftTokenId), "some new uri");
  }

  function testSetTokenURIOfNonExistentToken() public {
    address to = address(this);
    address from = address(0);

    vm.expectEmit(true, true, true, false);
    uint256 raftTokenId = raft.mint(to, "some uri");
    emit Transfer(from, to, raftTokenId);

    assertEq(raftTokenId, 1);
    assertEq(raft.balanceOf(to), 1);
    vm.expectRevert(bytes("_setTokenURI: URI set of nonexistent token"));
    raft.setTokenURI(999999999, "some new uri");
  }

  function testSetTokenURIAsNonOwner() public {
    address to = address(this);
    address from = address(0);
    address attacker = vm.addr(randomPrivateKey);

    vm.expectEmit(true, true, true, false);
    uint256 raftTokenId = raft.mint(to, "some uri");
    emit Transfer(from, to, raftTokenId);

    assertEq(raftTokenId, 1);
    assertEq(raft.balanceOf(to), 1);

    vm.prank(attacker);
    vm.expectRevert(bytes("Ownable: caller is not the owner"));
    raft.setTokenURI(raftTokenId, "some new uri");
  }

  function testTransferOwnership() public {
    address currentOwner = raft.owner();
    assertEq(currentOwner, address(this));
    address newOwner = vm.addr(randomPrivateKey);
    raft.transferOwnership(newOwner);
    assertEq(raft.owner(), newOwner);
  }

  function testTransferOwnershipFromNonOwner() public {
    address currentOwner = raft.owner();
    assertEq(currentOwner, address(this));
    address attacker = vm.addr(randomPrivateKey);
    vm.prank(attacker);
    vm.expectRevert(bytes("Ownable: caller is not the owner"));
    raft.transferOwnership(attacker);
  }
}
