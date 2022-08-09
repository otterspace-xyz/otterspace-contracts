// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

import "forge-std/Test.sol";
import { IERC165 } from "./IERC165.sol";

import { IERC721Metadata } from "./IERC721Metadata.sol";
import { IERC4973 } from "ERC4973/interfaces/IERC4973.sol";
import { Badges } from "./Badges.sol";
import { SpecDataHolder } from "./SpecDataHolder.sol";
import { Raft } from "./Raft.sol";

contract ERC1271Mock {
  bytes4 internal constant MAGICVALUE = 0x1626ba7e;
  bool private pass;

  constructor(bool pass_) {
    pass = pass_;
  }

  function isValidSignature(bytes32 hash, bytes memory signature) public view returns (bytes4) {
    if (pass) {
      return MAGICVALUE;
    } else {
      revert("permit not granted");
    }
  }
}

contract AccountAbstraction is ERC1271Mock {
  constructor(bool pass) ERC1271Mock(pass) {}

  function give(
    address collection,
    address to,
    string calldata uri,
    bytes calldata signature
  ) external virtual returns (uint256) {
    return Badges(collection).give(to, uri, signature);
  }

  function take(
    address collection,
    address from,
    string calldata uri,
    bytes calldata signature
  ) external virtual returns (uint256) {
    return Badges(collection).take(from, uri, signature);
  }

  function unequip(address collection, uint256 tokenId) public virtual {
    return Badges(collection).unequip(tokenId);
  }
}

contract NonAuthorizedCaller {
  function unequip(address collection, uint256 tokenId) external {
    Badges badges = Badges(collection);
    badges.unequip(tokenId);
  }
}

contract BadgesTest is Test {
  ERC1271Mock approver;
  ERC1271Mock rejecter;
  Badges badges;
  SpecDataHolder specDataHolder;
  Raft raft;
  AccountAbstraction aa;

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

    approver = new ERC1271Mock(true);
    rejecter = new ERC1271Mock(false);
    aa = new AccountAbstraction(true);

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

  function testSetDataHolder() public {
    address dataHolderAddress = address(specDataHolder);
    assertEq(badges.getDataHolderAddress(), dataHolderAddress);

    address newDataHolderAddress = vm.addr(randomPrivateKey);
    badges.setDataHolder(newDataHolderAddress);
    assertEq(badges.getDataHolderAddress(), newDataHolderAddress);
  }

  function testSetDataHolderAsNonOwner() public {
    address dataHolderAddress = address(specDataHolder);
    assertEq(badges.getDataHolderAddress(), dataHolderAddress);

    address newDataHolderAddress = vm.addr(randomPrivateKey);
    address attacker = vm.addr(randomPrivateKey);
    vm.prank(attacker);
    vm.expectRevert(bytes("Ownable: caller is not the owner"));
    badges.setDataHolder(newDataHolderAddress);
  }

  function testTransferOwnership() public {
    address currentOwner = badges.owner();
    assertEq(currentOwner, address(this));
    address newOwner = vm.addr(randomPrivateKey);
    badges.transferOwnership(newOwner);
    assertEq(badges.owner(), newOwner);
  }

  function testTransferOwnershipFromNonOwner() public {
    address currentOwner = badges.owner();
    assertEq(currentOwner, address(this));
    address attacker = vm.addr(randomPrivateKey);
    vm.prank(attacker);
    vm.expectRevert(bytes("Ownable: caller is not the owner"));
    badges.transferOwnership(attacker);
  }

  function testCreateSpecAsNonRaftOwner() public {
    address to = address(this);
    address from = address(0);

    vm.expectEmit(true, true, true, false);
    uint256 raftTokenId = raft.mint(to, "some uri");
    emit Transfer(from, to, raftTokenId);

    assertEq(raftTokenId, 1);
    assertEq(raft.balanceOf(to), 1);
    address attacker = vm.addr(randomPrivateKey);
    vm.prank(attacker);
    vm.expectRevert(bytes("createSpecAsRaftOwner: unauthorized"));
    badges.createSpecAsRaftOwner(specUri, raftTokenId);
  }

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

  // TODO: write test for a non-owner calling transferOwnership
  // tricky because we need to call a proxy to do this

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

  function testIfEmptyAddressReturnsBalanceZero() public {
    assertEq(badges.balanceOf(address(1337)), 0);
  }

  function testThrowOnZeroAddress() public {
    vm.expectRevert(bytes("balanceOf: address zero is not a valid owner_"));
    badges.balanceOf(address(0));
  }

  function testGetOwnerOfContract() public {
    assertEq(badges.owner(), address(this));
  }

  function testMintRaftToken() public {
    address to = address(this);
    address from = address(0);

    assertEq(raft.balanceOf(to), 0);
    vm.expectEmit(true, true, true, false);
    uint256 tokenId = raft.mint(to, "some uri");
    emit Transfer(from, to, tokenId);

    assertEq(tokenId, 1);
    assertEq(raft.balanceOf(to), 1);
  }

  function testBalanceIncreaseAfterMint() public {
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

  function testBalanceIncreaseAfterMintAndUnequip() public {
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

    NonAuthorizedCaller nac = new NonAuthorizedCaller();
    vm.expectRevert(bytes("unequip: sender must be owner"));

    nac.unequip(address(badges), tokenId);
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

    NonAuthorizedCaller nac = new NonAuthorizedCaller();
    vm.expectRevert(bytes("ownerOf: token doesn't exist"));

    nac.unequip(address(badges), 1337);
  }

  function testFailRequestingNonExistentTokenURI() public view {
    badges.tokenURI(1337);
  }

  function testFailGetBonderOfNonExistentTokenId() public view {
    badges.ownerOf(1337);
  }

  function testGiveWithRejectingERC1271Contract() public {
    address to = address(rejecter);
    bytes memory signature;

    vm.expectRevert(bytes("_safeCheckAgreement: invalid signature"));
    badges.give(to, specUri, signature);
  }

  function testTakeWithRejectingERC1271Contract() public {
    address from = address(rejecter);
    bytes memory signature;

    vm.expectRevert(bytes("_safeCheckAgreement: invalid signature"));
    badges.take(from, specUri, signature);
  }

  function testGiveWithApprovingERC1271Contract() public {
    address to = address(approver);
    address from = address(0);
    bytes memory signature;
    createRaftAndRegisterSpec();

    vm.expectEmit(true, true, true, false);
    uint256 tokenId = badges.give(to, specUri, signature);
    emit Transfer(from, to, tokenId);

    assertEq(badges.balanceOf(to), 1);
    assertEq(badges.tokenURI(tokenId), specUri);
    assertEq(badges.ownerOf(tokenId), to);
  }

  // do we actually need this? it's just a copy of the above test
  function testTakeWithApprovingERC1271Contract() public {
    address to = address(this);
    address from = address(approver);
    bytes memory signature;

    createRaftAndRegisterSpec();
    uint256 tokenId = badges.take(from, specUri, signature);

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

  function testGiveWithDifferentTokenURI() public {
    address from = address(this);
    address to = passiveAddress;

    string memory falseTokenURI = "https://badstuff.com";
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

    bytes32 hash = badges.getHash(from, to, specUri);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);
    address unauthorizedTo = address(1337);

    vm.expectRevert(bytes("_safeCheckAgreement: invalid signature"));
    uint256 tokenId = badges.give(unauthorizedTo, specUri, signature);
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

  function testGiveAndUnequipAndRegive() public {
    createRaftAndRegisterSpec();
    string memory tokenURI = "some spec uri";
    address to = address(aa);
    address from = address(0);

    bytes memory signature;
    vm.expectEmit(true, true, true, false);
    uint256 tokenId = badges.give(to, specUri, signature);
    emit Transfer(from, to, tokenId);

    assertEq(badges.balanceOf(to), 1);
    assertEq(badges.tokenURI(tokenId), tokenURI);
    assertEq(badges.ownerOf(tokenId), to);

    vm.expectEmit(true, true, true, false);
    aa.unequip(address(badges), tokenId);
    emit Transfer(to, from, tokenId);
    assertEq(badges.balanceOf(to), 0);

    vm.expectEmit(true, true, true, false);
    uint256 tokenId2 = badges.give(to, specUri, signature);
    emit Transfer(from, to, tokenId);

    assertEq(badges.balanceOf(to), 1);
    assertEq(badges.tokenURI(tokenId2), tokenURI);
    assertEq(badges.ownerOf(tokenId2), to);
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

  function testPreventGivingToSelf() public {
    address to = address(aa);
    bytes memory signature;

    vm.expectRevert(bytes("give: cannot give from self"));
    aa.give(address(badges), to, specUri, signature);
  }

  function testPreventTakingToSelf() public {
    address from = address(aa);
    bytes memory signature;

    vm.expectRevert(bytes("take: cannot take from self"));
    aa.take(address(badges), from, specUri, signature);
  }
}
