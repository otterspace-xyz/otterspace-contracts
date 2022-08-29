// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import { IERC721Metadata } from "./interfaces/IERC721Metadata.sol";
import { IERC4973 } from "ERC4973/interfaces/IERC4973.sol";
import { Badges } from "./Badges.sol";
import { SpecDataHolder } from "./SpecDataHolder.sol";
import { Raft } from "./Raft.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UUPSProxy is ERC1967Proxy {
  constructor(address _implementation, bytes memory _data) ERC1967Proxy(_implementation, _data) {}
}

contract BadgesTest is Test {
  Badges badgesImplementationV1;
  SpecDataHolder specDataHolderImplementationV1;
  Raft raftImplementationV1;

  UUPSProxy badgesProxy;
  UUPSProxy raftProxy;
  UUPSProxy specDataHolderProxy;

  Badges badgesWrappedProxyV1;
  Raft raftWrappedProxyV1;
  SpecDataHolder specDataHolderWrappedProxyV1;

  address passiveAddress = 0x0f6A79A579658E401E0B81c6dde1F2cd51d97176;
  uint256 passivePrivateKey = 0xad54bdeade5537fb0a553190159783e45d02d316a992db05cbed606d3ca36b39;
  uint256 randomPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
  string specUri;

  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  function setUp() public {
    address to = address(this);

    badgesImplementationV1 = new Badges();
    specDataHolderImplementationV1 = new SpecDataHolder();
    raftImplementationV1 = new Raft();

    badgesProxy = new UUPSProxy(address(badgesImplementationV1), "");
    raftProxy = new UUPSProxy(address(raftImplementationV1), "");
    specDataHolderProxy = new UUPSProxy(address(specDataHolderImplementationV1), "");

    badgesWrappedProxyV1 = Badges(address(badgesProxy));
    raftWrappedProxyV1 = Raft(address(raftProxy));
    specDataHolderWrappedProxyV1 = SpecDataHolder(address(specDataHolderProxy));

    badgesWrappedProxyV1.initialize("Badges", "BADGES", "0.1.0", to, address(specDataHolderProxy));
    raftWrappedProxyV1.initialize(to, "Raft", "RAFT");
    specDataHolderWrappedProxyV1.initialize(address(raftProxy), to);

    specDataHolderWrappedProxyV1.setBadgesAddress(address(badgesProxy));
    specUri = "some spec uri";

    vm.label(passiveAddress, "passive");
  }

  // helper function
  function createRaftAndRegisterSpec() internal {
    address to = address(this);
    address from = address(0);

    vm.expectEmit(true, true, true, false);
    uint256 raftTokenId = raftWrappedProxyV1.mint(to, "some uri");
    emit Transfer(from, to, raftTokenId);

    assertEq(raftTokenId, 1);
    assertEq(raftWrappedProxyV1.balanceOf(to), 1);

    badgesWrappedProxyV1.createSpecAsRaftHolder(specUri, raftTokenId);
    assertEq(specDataHolderWrappedProxyV1.isSpecRegistered(specUri), true);
  }

  // helper function
  function getSignature() internal returns (bytes memory) {
    address to = address(this);
    bytes32 hash = badgesWrappedProxyV1.getHash(to, passiveAddress, specUri);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);
    return signature;
  }

  function testIERC721Metadata() public {
    assertTrue(badgesWrappedProxyV1.supportsInterface(type(IERC721Metadata).interfaceId));
  }

  function testIERC4973() public {
    bytes4 interfaceId = type(IERC4973).interfaceId;
    assertEq(interfaceId, bytes4(0x8d7bac72));
    assertTrue(badgesWrappedProxyV1.supportsInterface(interfaceId));
  }

  function testCheckMetadata() public {
    assertEq(badgesWrappedProxyV1.name(), "Badges");
    assertEq(badgesWrappedProxyV1.symbol(), "BADGES");
  }

  function testIfEmptyAddressReturnsBalanceZero(address fuzzAddress) public {
    vm.assume(fuzzAddress != address(0));
    assertEq(badgesWrappedProxyV1.balanceOf(address(fuzzAddress)), 0);
  }

  function testThrowOnZeroAddress() public {
    vm.expectRevert(bytes("balanceOf: address zero is not a valid owner_"));
    badgesWrappedProxyV1.balanceOf(address(0));
  }

  function testFailGetOwnerOfNonExistentTokenId(uint256 tokenId) public view {
    // needs assert
    badgesWrappedProxyV1.ownerOf(tokenId);
  }

  // DATA HOLDER TESTS

  function testSetDataHolder(address fuzzAddress) public {
    address dataHolderAddress = address(specDataHolderProxy);
    assertEq(badgesWrappedProxyV1.getDataHolderAddress(), dataHolderAddress);

    badgesWrappedProxyV1.setDataHolder(fuzzAddress);
    assertEq(badgesWrappedProxyV1.getDataHolderAddress(), fuzzAddress);
  }

  function testSetDataHolderAsNonOwner() public {
    address dataHolderAddress = address(specDataHolderProxy);
    assertEq(badgesWrappedProxyV1.getDataHolderAddress(), dataHolderAddress);
    address randomAddress = vm.addr(randomPrivateKey);
    vm.prank(randomAddress);
    vm.expectRevert(bytes("Ownable: caller is not the owner"));
    badgesWrappedProxyV1.setDataHolder(randomAddress);
  }

  // OWNERSHIP TESTS

  function testGetOwnerOfContract() public {
    assertEq(badgesWrappedProxyV1.owner(), address(this));
  }

  function testTransferOwnership(address fuzzAddress) public {
    vm.assume(fuzzAddress != address(0));
    address currentOwner = badgesWrappedProxyV1.owner();
    assertEq(currentOwner, address(this));
    badgesWrappedProxyV1.transferOwnership(fuzzAddress);
    assertEq(badgesWrappedProxyV1.owner(), fuzzAddress);
  }

  function testTransferOwnershipFromNonOwner() public {
    address currentOwner = badgesWrappedProxyV1.owner();
    assertEq(currentOwner, address(this));
    address randomAddress = vm.addr(randomPrivateKey);
    vm.prank(randomAddress);
    vm.expectRevert(bytes("Ownable: caller is not the owner"));
    badgesWrappedProxyV1.transferOwnership(randomAddress);
  }

  // // CREATE SPEC TESTS

  function testCreateSpecAsNonRaftOwner() public {
    address to = address(this);
    address from = address(0);

    vm.expectEmit(true, true, true, false);
    uint256 raftTokenId = raftWrappedProxyV1.mint(to, "some uri");
    emit Transfer(from, to, raftTokenId);

    assertEq(raftTokenId, 1);
    assertEq(raftWrappedProxyV1.balanceOf(to), 1);

    address randomAddress = vm.addr(randomPrivateKey);
    vm.prank(randomAddress);

    vm.expectRevert(bytes("createSpec: unauthorized"));
    badgesWrappedProxyV1.createSpecAsRaftHolder(specUri, raftTokenId);
  }

  // can't test this one with fuzzing because the owner is set in the "setup"
  // function above, so replacing "to" with "fuzzAddress" will always fail
  function testCreateSpecTwice() public {
    address to = address(this);
    address from = address(0);

    vm.expectEmit(true, true, true, false);
    uint256 raftTokenId = raftWrappedProxyV1.mint(to, "some token uri");
    emit Transfer(from, to, raftTokenId);
    assertEq(raftTokenId, 1);
    assertEq(raftWrappedProxyV1.balanceOf(to), 1);
    badgesWrappedProxyV1.createSpecAsRaftHolder(specUri, raftTokenId);
    vm.expectRevert(bytes("createSpec: spec already registered"));
    badgesWrappedProxyV1.createSpecAsRaftHolder(specUri, raftTokenId);
  }

  function testSenderIsntRaftOwner() public {
    address to = address(this);
    address from = address(0);

    vm.expectEmit(true, true, true, false);
    uint256 raftTokenId = raftWrappedProxyV1.mint(to, "some token uri");
    emit Transfer(from, to, raftTokenId);
    assertEq(raftTokenId, 1);
    assertEq(raftWrappedProxyV1.balanceOf(to), 1);
    vm.prank(address(0));
    vm.expectRevert(bytes("createSpec: unauthorized"));
    badgesWrappedProxyV1.createSpecAsRaftHolder(specUri, raftTokenId);
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
    uint256 tokenId = badgesWrappedProxyV1.take(passiveAddress, specUri, signature);
    emit Transfer(from, to, tokenId);

    assertEq(badgesWrappedProxyV1.balanceOf(to), 1);
    assertEq(badgesWrappedProxyV1.tokenURI(tokenId), specUri);
    assertEq(badgesWrappedProxyV1.ownerOf(tokenId), to);
  }

  function testTakeWithDifferentTokenURI() public {
    address to = address(this);
    string memory falseTokenURI = "https://badstuff.com";
    bytes32 hash = badgesWrappedProxyV1.getHash(passiveAddress, to, falseTokenURI);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    vm.expectRevert(bytes("safeCheckAgreement: invalid signature"));
    uint256 tokenId = badgesWrappedProxyV1.take(passiveAddress, specUri, signature);

    assertEq(0, tokenId);
  }

  function testTakeWithUnauthorizedSender() public {
    address to = address(this);

    bytes32 hash = badgesWrappedProxyV1.getHash(passiveAddress, to, specUri);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);
    address unauthorizedFrom = address(1337);

    vm.expectRevert(bytes("safeCheckAgreement: invalid signature"));
    uint256 tokenId = badgesWrappedProxyV1.take(unauthorizedFrom, specUri, signature);
    assertEq(0, tokenId);
  }

  function testTakeAndUnequipAndRetake() public {
    createRaftAndRegisterSpec();
    address to = address(this);
    address from = address(0);

    bytes memory signature = getSignature();

    vm.expectEmit(true, true, true, false);
    uint256 tokenId = badgesWrappedProxyV1.take(passiveAddress, specUri, signature);
    emit Transfer(from, to, tokenId);

    assertEq(badgesWrappedProxyV1.balanceOf(to), 1);
    assertEq(badgesWrappedProxyV1.tokenURI(tokenId), specUri);
    assertEq(badgesWrappedProxyV1.ownerOf(tokenId), to);

    vm.expectEmit(true, true, true, false);
    badgesWrappedProxyV1.unequip(tokenId);
    emit Transfer(to, from, tokenId);
    assertEq(badgesWrappedProxyV1.balanceOf(to), 0);

    vm.expectEmit(true, true, true, false);
    uint256 tokenId2 = badgesWrappedProxyV1.take(passiveAddress, specUri, signature);
    emit Transfer(from, to, tokenId);

    assertEq(badgesWrappedProxyV1.balanceOf(to), 1);
    assertEq(badgesWrappedProxyV1.tokenURI(tokenId2), specUri);
    assertEq(badgesWrappedProxyV1.ownerOf(tokenId2), to);
  }

  function testTakeWithAlreadyUsedVoucher() public {
    createRaftAndRegisterSpec();
    address to = address(this);
    address from = address(0);
    bytes memory signature = getSignature();
    vm.expectEmit(true, true, true, false);

    uint256 tokenId = badgesWrappedProxyV1.take(passiveAddress, specUri, signature);
    emit Transfer(from, to, tokenId);

    vm.expectRevert(bytes("safeCheckAgreement: already used"));
    badgesWrappedProxyV1.take(passiveAddress, specUri, signature);
  }

  function testPreventTakingToSelf() public {
    address to = address(this);
    bytes memory signature;

    vm.expectRevert(bytes("take: cannot take from self"));
    badgesWrappedProxyV1.take(to, specUri, signature);
  }

  // GIVE TESTS
  function testBalanceIncreaseAfterGive() public {
    createRaftAndRegisterSpec();
    address from = address(this);
    address to = passiveAddress;

    bytes32 hash = badgesWrappedProxyV1.getHash(from, to, specUri);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    uint256 tokenId = badgesWrappedProxyV1.give(to, specUri, signature);
    assertEq(badgesWrappedProxyV1.balanceOf(to), 1);
    assertEq(badgesWrappedProxyV1.tokenURI(tokenId), specUri);
    assertEq(badgesWrappedProxyV1.ownerOf(tokenId), to);
  }

  function testGiveWithDifferentTokenURI(string memory falseTokenURI) public {
    address from = address(this);
    address to = passiveAddress;

    bytes32 hash = badgesWrappedProxyV1.getHash(from, to, falseTokenURI);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    vm.expectRevert(bytes("safeCheckAgreement: invalid signature"));

    uint256 tokenId = badgesWrappedProxyV1.give(to, specUri, signature);
    assertEq(0, tokenId);
  }

  function testGiveWithUnauthorizedSender() public {
    address from = address(this);
    address to = passiveAddress;
    address randomAddress = vm.addr(randomPrivateKey);
    vm.prank(randomAddress);
    bytes32 hash = badgesWrappedProxyV1.getHash(from, to, specUri);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);
    vm.expectRevert(bytes("safeCheckAgreement: invalid signature"));
    uint256 tokenId = badgesWrappedProxyV1.give(randomAddress, specUri, signature);
    assertEq(0, tokenId);
  }

  function testGiveAndUnequipAndRegive() public {
    createRaftAndRegisterSpec();
    address from = address(this);
    address to = passiveAddress;

    bytes32 hash = badgesWrappedProxyV1.getHash(from, to, specUri);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);
    vm.expectEmit(true, true, true, false);

    uint256 tokenId = badgesWrappedProxyV1.give(to, specUri, signature);
    emit Transfer(address(0), to, tokenId);

    assertEq(badgesWrappedProxyV1.balanceOf(to), 1);
    assertEq(badgesWrappedProxyV1.tokenURI(tokenId), specUri);
    assertEq(badgesWrappedProxyV1.ownerOf(tokenId), to);

    vm.prank(to);
    vm.expectEmit(true, true, true, false);
    badgesWrappedProxyV1.unequip(tokenId);
    emit Transfer(to, address(0), tokenId);
    assertEq(badgesWrappedProxyV1.balanceOf(to), 0);

    vm.expectEmit(true, true, true, false);
    vm.prank(from);
    uint256 tokenId2 = badgesWrappedProxyV1.give(to, specUri, signature);
    emit Transfer(address(0), to, tokenId);

    assertEq(badgesWrappedProxyV1.balanceOf(to), 1);
    assertEq(badgesWrappedProxyV1.tokenURI(tokenId2), specUri);
    assertEq(badgesWrappedProxyV1.ownerOf(tokenId2), to);
  }

  function testGiveWithAlreadyUsedVoucher() public {
    createRaftAndRegisterSpec();
    address from = address(this);
    address to = passiveAddress;

    bytes32 hash = badgesWrappedProxyV1.getHash(from, to, specUri);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    badgesWrappedProxyV1.give(to, specUri, signature);

    vm.expectRevert(bytes("safeCheckAgreement: already used"));
    badgesWrappedProxyV1.give(to, specUri, signature);
  }

  function testPreventGivingToSelf() public {
    address to = address(this);
    bytes memory signature;

    vm.expectRevert(bytes("give: cannot give from self"));
    badgesWrappedProxyV1.give(to, specUri, signature);
  }

  // UNEQUIP TESTS
  function testBalanceDecreaseAfterUnequip() public {
    address to = address(this);
    assertEq(badgesWrappedProxyV1.balanceOf(to), 0);
    bytes memory signature = getSignature();
    address from = address(0);

    createRaftAndRegisterSpec();
    vm.expectEmit(true, true, true, false);
    uint256 tokenId = badgesWrappedProxyV1.take(passiveAddress, specUri, signature);
    emit Transfer(from, to, tokenId);
    assertEq(badgesWrappedProxyV1.balanceOf(to), 1);
    assertEq(badgesWrappedProxyV1.tokenURI(tokenId), specUri);
    assertEq(badgesWrappedProxyV1.ownerOf(tokenId), to);

    vm.expectEmit(true, true, true, false);
    badgesWrappedProxyV1.unequip(tokenId);
    emit Transfer(to, from, tokenId);
    assertEq(badgesWrappedProxyV1.balanceOf(to), 0);
  }

  function testUnequippingAsNonAuthorizedAccount() public {
    address to = address(this);
    address from = address(0);
    bytes memory signature = getSignature();

    createRaftAndRegisterSpec();
    vm.expectEmit(true, true, true, false);
    uint256 tokenId = badgesWrappedProxyV1.take(passiveAddress, specUri, signature);
    emit Transfer(from, to, tokenId);

    assertEq(badgesWrappedProxyV1.ownerOf(tokenId), to);
    assertEq(badgesWrappedProxyV1.tokenURI(tokenId), specUri);

    vm.prank(from);
    vm.expectRevert(bytes("unequip: sender must be owner"));
    badgesWrappedProxyV1.unequip(tokenId);
  }

  function testUnequippingNonExistentTokenId() public {
    address to = address(this);
    address from = address(0);
    bytes memory signature = getSignature();

    createRaftAndRegisterSpec();
    vm.expectEmit(true, true, true, false);
    uint256 tokenId = badgesWrappedProxyV1.take(passiveAddress, specUri, signature);
    emit Transfer(from, to, tokenId);

    assertEq(badgesWrappedProxyV1.ownerOf(tokenId), to);
    assertEq(badgesWrappedProxyV1.tokenURI(tokenId), specUri);

    vm.expectRevert(bytes("unequip: token doesn't exist"));
    badgesWrappedProxyV1.unequip(1337);
  }
}
