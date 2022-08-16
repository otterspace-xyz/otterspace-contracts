// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.7;

import "forge-std/Test.sol";
import { IERC165 } from "./IERC165.sol";

import { IERC721Metadata } from "./IERC721Metadata.sol";
import { IERC4973 } from "ERC4973/interfaces/IERC4973.sol";
import { Badges } from "./Badges.sol";
import { SpecDataHolder } from "./SpecDataHolder.sol";
import { Raft } from "./Raft.sol";

contract BadgesTest is Test {
  Badges badges;
  SpecDataHolder specDataHolder;
  Raft raft;

  address passiveAddress = 0x0f6A79A579658E401E0B81c6dde1F2cd51d97176;
  uint256 passivePrivateKey = 0xad54bdeade5537fb0a553190159783e45d02d316a992db05cbed606d3ca36b39;
  uint256 randomPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
  string specUri;

  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  function setUp() public {
    address to = address(this);

    badges = new Badges();
    specDataHolder = new SpecDataHolder();
    raft = new Raft();
    badges.initialize("Badges", "BADGES", "0.1.0", to, address(specDataHolder));
    raft.initialize(to, "Raft", "RAFT");
    specDataHolder.initialize(address(raft), to);
    specDataHolder.setBadgesAddress(address(badges));
    specUri = "some spec uri";

    vm.label(passiveAddress, "passive");
  }

  // helper function
  function createRaftAndRegisterSpec() internal {
    address to = address(this);
    address from = address(0);

    vm.expectEmit(true, true, true, false);
    uint256 raftTokenId = raft.mint(to, "some uri");
    emit Transfer(from, to, raftTokenId);

    assertEq(raftTokenId, 1);
    assertEq(raft.balanceOf(to), 1);

    badges.createSpecAsRaftOwner(specUri, raftTokenId);
    assertEq(specDataHolder.specIsRegistered(specUri), true);
  }

  // helper function
  function getSignature() internal returns (bytes memory) {
    address to = address(this);
    bytes32 hash = badges.getHash(to, passiveAddress, specUri);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);
    return signature;
  }

  function testIERC165() public {
    assertTrue(badges.supportsInterface(type(IERC165).interfaceId));
  }

  function testIERC721Metadata() public {
    assertTrue(badges.supportsInterface(type(IERC721Metadata).interfaceId));
  }

  function testIERC4973() public {
    bytes4 interfaceId = type(IERC4973).interfaceId;
    assertEq(interfaceId, bytes4(0x8d7bac72));
    assertTrue(badges.supportsInterface(interfaceId));
  }

  function testCheckMetadata() public {
    assertEq(badges.name(), "Badges");
    assertEq(badges.symbol(), "BADGES");
  }

  function testIfEmptyAddressReturnsBalanceZero(address fuzzAddress) public {
    vm.assume(fuzzAddress != address(0));
    assertEq(badges.balanceOf(address(fuzzAddress)), 0);
  }

  function testThrowOnZeroAddress() public {
    vm.expectRevert(bytes("balanceOf: address zero is not a valid owner_"));
    badges.balanceOf(address(0));
  }

  function testFailGetOwnerOfNonExistentTokenId(uint256 tokenId) public view {
    // needs assert
    badges.ownerOf(tokenId);
  }

  // DATA HOLDER TESTS

  function testSetDataHolder(address fuzzAddress) public {
    address dataHolderAddress = address(specDataHolder);
    assertEq(badges.getDataHolderAddress(), dataHolderAddress);

    badges.setDataHolder(fuzzAddress);
    assertEq(badges.getDataHolderAddress(), fuzzAddress);
  }

  function testSetDataHolderAsNonOwner() public {
    address dataHolderAddress = address(specDataHolder);
    assertEq(badges.getDataHolderAddress(), dataHolderAddress);
    address randomAddress = vm.addr(randomPrivateKey);
    vm.prank(randomAddress);
    vm.expectRevert(bytes("Ownable: caller is not the owner"));
    badges.setDataHolder(randomAddress);
  }

  // OWNERSHIP TESTS

  function testGetOwnerOfContract() public {
    assertEq(badges.owner(), address(this));
  }

  function testTransferOwnership(address fuzzAddress) public {
    vm.assume(fuzzAddress != address(0));
    address currentOwner = badges.owner();
    assertEq(currentOwner, address(this));
    badges.transferOwnership(fuzzAddress);
    assertEq(badges.owner(), fuzzAddress);
  }

  function testTransferOwnershipFromNonOwner() public {
    address currentOwner = badges.owner();
    assertEq(currentOwner, address(this));
    address randomAddress = vm.addr(randomPrivateKey);
    vm.prank(randomAddress);
    vm.expectRevert(bytes("Ownable: caller is not the owner"));
    badges.transferOwnership(randomAddress);
  }

  // CREATE SPEC TESTS

  function testCreateSpecAsNonRaftOwner() public {
    address to = address(this);
    address from = address(0);

    vm.expectEmit(true, true, true, false);
    uint256 raftTokenId = raft.mint(to, "some uri");
    emit Transfer(from, to, raftTokenId);

    assertEq(raftTokenId, 1);
    assertEq(raft.balanceOf(to), 1);
    address randomAddress = vm.addr(randomPrivateKey);

    vm.prank(randomAddress);

    vm.expectRevert(bytes("createSpecAsRaftOwner: unauthorized"));
    badges.createSpecAsRaftOwner(specUri, raftTokenId);
  }

  // can't test this one with fuzzing because the owner is set in the "setup"
  // function above, so replacing "to" with "fuzzAddress" will always fail
  function testCreateSpecAsRaftOwnerTwice() public {
    address to = address(this);
    address from = address(0);

    vm.expectEmit(true, true, true, false);
    uint256 raftTokenId = raft.mint(to, "some token uri");
    emit Transfer(from, to, raftTokenId);
    assertEq(raftTokenId, 1);
    assertEq(raft.balanceOf(to), 1);
    badges.createSpecAsRaftOwner(specUri, raftTokenId);
    vm.expectRevert(bytes("createSpecAsRaftOwner: spec already registered"));
    badges.createSpecAsRaftOwner(specUri, raftTokenId);
  }

  function testSenderIsntRaftOwner() public {
    address to = address(this);
    address from = address(0);

    vm.expectEmit(true, true, true, false);
    uint256 raftTokenId = raft.mint(to, "some token uri");
    emit Transfer(from, to, raftTokenId);
    assertEq(raftTokenId, 1);
    assertEq(raft.balanceOf(to), 1);
    vm.prank(address(0));
    vm.expectRevert(bytes("createSpecAsRaftOwner: unauthorized"));
    badges.createSpecAsRaftOwner(specUri, raftTokenId);
  }

  // TODO: write test for a non-owner calling transferOwnership
  // tricky because we need to call a proxy to do this

  // TAKE TESTS
  // happy path
  function testBalanceIncreaseAfterTake() public {
    address to = address(this);
    address from = address(0);

    createRaftAndRegisterSpec();
    bytes memory signature = getSignature();
    vm.expectEmit(true, true, true, false);
    uint256 tokenId = badges.take(passiveAddress, specUri, signature);
    emit Transfer(from, to, tokenId);

    assertEq(badges.balanceOf(to), 1);
    assertEq(badges.tokenURI(tokenId), specUri);
    assertEq(badges.ownerOf(tokenId), to);
  }

  function testTakeWithDifferentTokenURI() public {
    address to = address(this);
    string memory falseTokenURI = "https://badstuff.com";
    bytes32 hash = badges.getHash(passiveAddress, to, falseTokenURI);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    vm.expectRevert(bytes("_safeCheckAgreement: invalid signature"));
    uint256 tokenId = badges.take(passiveAddress, specUri, signature);

    assertEq(0, tokenId);
  }

  function testTakeWithUnauthorizedSender() public {
    address to = address(this);

    bytes32 hash = badges.getHash(passiveAddress, to, specUri);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);
    address unauthorizedFrom = address(1337);

    vm.expectRevert(bytes("_safeCheckAgreement: invalid signature"));
    uint256 tokenId = badges.take(unauthorizedFrom, specUri, signature);
    assertEq(0, tokenId);
  }

  function testTakeAndUnequipAndRetake() public {
    createRaftAndRegisterSpec();
    address to = address(this);
    address from = address(0);

    bytes memory signature = getSignature();

    vm.expectEmit(true, true, true, false);
    uint256 tokenId = badges.take(passiveAddress, specUri, signature);
    emit Transfer(from, to, tokenId);

    assertEq(badges.balanceOf(to), 1);
    assertEq(badges.tokenURI(tokenId), specUri);
    assertEq(badges.ownerOf(tokenId), to);

    vm.expectEmit(true, true, true, false);
    badges.unequip(tokenId);
    emit Transfer(to, from, tokenId);
    assertEq(badges.balanceOf(to), 0);

    vm.expectEmit(true, true, true, false);
    uint256 tokenId2 = badges.take(passiveAddress, specUri, signature);
    emit Transfer(from, to, tokenId);

    assertEq(badges.balanceOf(to), 1);
    assertEq(badges.tokenURI(tokenId2), specUri);
    assertEq(badges.ownerOf(tokenId2), to);
  }

  function testTakeWithAlreadyUsedVoucher() public {
    createRaftAndRegisterSpec();
    address to = address(this);
    address from = address(0);
    bytes memory signature = getSignature();
    vm.expectEmit(true, true, true, false);

    uint256 tokenId = badges.take(passiveAddress, specUri, signature);
    emit Transfer(from, to, tokenId);

    vm.expectRevert(bytes("_safeCheckAgreement: already used"));
    badges.take(passiveAddress, specUri, signature);
  }

  function testPreventTakingToSelf() public {
    address to = address(this);
    bytes memory signature;

    vm.expectRevert(bytes("take: cannot take from self"));
    badges.take(to, specUri, signature);
  }

  // GIVE TESTS
  function testBalanceIncreaseAfterGive() public {
    createRaftAndRegisterSpec();
    address from = address(this);
    address to = passiveAddress;

    bytes32 hash = badges.getHash(from, to, specUri);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    uint256 tokenId = badges.give(to, specUri, signature);
    assertEq(badges.balanceOf(to), 1);
    assertEq(badges.tokenURI(tokenId), specUri);
    assertEq(badges.ownerOf(tokenId), to);
  }

  function testGiveWithDifferentTokenURI(string memory falseTokenURI) public {
    address from = address(this);
    address to = passiveAddress;

    bytes32 hash = badges.getHash(from, to, falseTokenURI);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    vm.expectRevert(bytes("_safeCheckAgreement: invalid signature"));

    uint256 tokenId = badges.give(to, specUri, signature);
    assertEq(0, tokenId);
  }

  function testGiveWithUnauthorizedSender() public {
    address from = address(this);
    address to = passiveAddress;
    address randomAddress = vm.addr(randomPrivateKey);
    vm.prank(randomAddress);
    bytes32 hash = badges.getHash(from, to, specUri);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);
    vm.expectRevert(bytes("_safeCheckAgreement: invalid signature"));
    uint256 tokenId = badges.give(randomAddress, specUri, signature);
    assertEq(0, tokenId);
  }

  function testGiveAndUnequipAndRegive() public {
    createRaftAndRegisterSpec();
    address from = address(this);
    address to = passiveAddress;

    bytes32 hash = badges.getHash(from, to, specUri);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);
    vm.expectEmit(true, true, true, false);

    uint256 tokenId = badges.give(to, specUri, signature);
    emit Transfer(address(0), to, tokenId);

    assertEq(badges.balanceOf(to), 1);
    assertEq(badges.tokenURI(tokenId), specUri);
    assertEq(badges.ownerOf(tokenId), to);

    vm.prank(to);
    vm.expectEmit(true, true, true, false);
    badges.unequip(tokenId);
    emit Transfer(to, address(0), tokenId);
    assertEq(badges.balanceOf(to), 0);

    vm.expectEmit(true, true, true, false);
    vm.prank(from);
    uint256 tokenId2 = badges.give(to, specUri, signature);
    emit Transfer(address(0), to, tokenId);

    assertEq(badges.balanceOf(to), 1);
    assertEq(badges.tokenURI(tokenId2), specUri);
    assertEq(badges.ownerOf(tokenId2), to);
  }

  function testGiveWithAlreadyUsedVoucher() public {
    createRaftAndRegisterSpec();
    address from = address(this);
    address to = passiveAddress;

    bytes32 hash = badges.getHash(from, to, specUri);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    badges.give(to, specUri, signature);

    vm.expectRevert(bytes("_safeCheckAgreement: already used"));
    badges.give(to, specUri, signature);
  }

  function testPreventGivingToSelf() public {
    address to = address(this);
    bytes memory signature;

    vm.expectRevert(bytes("give: cannot give from self"));
    badges.give(to, specUri, signature);
  }

  // UNEQUIP TESTS
  function testBalanceDecreaseAfterUnequip() public {
    address to = address(this);
    assertEq(badges.balanceOf(to), 0);
    bytes memory signature = getSignature();
    address from = address(0);

    createRaftAndRegisterSpec();
    vm.expectEmit(true, true, true, false);
    uint256 tokenId = badges.take(passiveAddress, specUri, signature);
    emit Transfer(from, to, tokenId);
    assertEq(badges.balanceOf(to), 1);
    assertEq(badges.tokenURI(tokenId), specUri);
    assertEq(badges.ownerOf(tokenId), to);

    vm.expectEmit(true, true, true, false);
    badges.unequip(tokenId);
    emit Transfer(to, from, tokenId);
    assertEq(badges.balanceOf(to), 0);
  }

  function testUnequippingAsNonAuthorizedAccount() public {
    address to = address(this);
    address from = address(0);
    bytes memory signature = getSignature();

    createRaftAndRegisterSpec();
    vm.expectEmit(true, true, true, false);
    uint256 tokenId = badges.take(passiveAddress, specUri, signature);
    emit Transfer(from, to, tokenId);

    assertEq(badges.ownerOf(tokenId), to);
    assertEq(badges.tokenURI(tokenId), specUri);

    vm.prank(from);
    vm.expectRevert(bytes("unequip: sender must be owner"));
    badges.unequip(tokenId);
  }

  function testUnequippingNonExistentTokenId() public {
    address to = address(this);
    address from = address(0);
    bytes memory signature = getSignature();

    createRaftAndRegisterSpec();
    vm.expectEmit(true, true, true, false);
    uint256 tokenId = badges.take(passiveAddress, specUri, signature);
    emit Transfer(from, to, tokenId);

    assertEq(badges.ownerOf(tokenId), to);
    assertEq(badges.tokenURI(tokenId), specUri);

    vm.expectRevert(bytes("ownerOf: token doesn't exist"));

    badges.unequip(1337);
  }
}
