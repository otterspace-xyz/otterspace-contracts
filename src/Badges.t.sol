// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import { IERC721Metadata } from "./interfaces/IERC721Metadata.sol";
import { IERC4973 } from "ERC4973/interfaces/IERC4973.sol";
import { Badges } from "./Badges.sol";
import { SpecDataHolder } from "./SpecDataHolder.sol";
import { Raft } from "./Raft.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Merkle } from "murky/src/Merkle.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

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

  uint256 raftHolderPrivateKey = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
  address raftHolderAddress = vm.addr(0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d);

  uint256 claimantPrivateKey = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;
  address claimantAddress = vm.addr(0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a);

  string[] specUris = ["spec1", "spec2"];
  string badTokenUri = "bad token uri";

  string err721InvalidTokenId = "ERC721: invalid token ID";
  string errBadgeAlreadyRevoked = "revokeBadge: badge already revoked";
  string errBalanceOfNotValidOwner = "balanceOf: address zero is not a valid owner_";
  string errCannotGiveToSelf = "give: cannot give to self";
  string errCannotTakeFromSelf = "take: cannot take from self";
  string errInvalidSig = "safeCheckAgreement: invalid signature";
  string errNoSpecUris = "refreshMetadata: no spec uris provided";
  string errNotOwner = "Ownable: caller is not the owner";
  string errNotRaftOwner = "createSpec: unauthorized";
  string errNotRevoked = "reinstateBadge: badge not revoked";
  string errSafeCheckUsed = "safeCheckAgreement: already used";
  string errSpecAlreadyRegistered = "createSpec: spec already registered";
  string errSpecNotRegistered = "mint: spec is not registered";
  string errGiveUnauthorized = "give: unauthorized";
  string errUnequipSenderNotOwner = "unequip: sender must be owner";
  string errTakeUnauthorized = "take: unauthorized issuer";
  string errMerkleInvalidLeaf = "safeCheckMerkleAgreement: invalid leaf";
  string errMerkleInvalidSignature = "safeCheckMerkleAgreement: invalid signature";
  string tokenDoesntExistErr = "tokenExists: token doesn't exist";
  string tokenExistsErr = "mint: tokenID exists";
  string specUri = "some spec uri";

  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event RefreshMetadata(string[] specUris, address sender);

  function setUp() public {
    address contractOwner = address(this);

    badgesImplementationV1 = new Badges();
    specDataHolderImplementationV1 = new SpecDataHolder();
    raftImplementationV1 = new Raft();

    badgesProxy = new UUPSProxy(address(badgesImplementationV1), "");
    raftProxy = new UUPSProxy(address(raftImplementationV1), "");
    specDataHolderProxy = new UUPSProxy(address(specDataHolderImplementationV1), "");

    badgesWrappedProxyV1 = Badges(address(badgesProxy));
    raftWrappedProxyV1 = Raft(address(raftProxy));
    specDataHolderWrappedProxyV1 = SpecDataHolder(address(specDataHolderProxy));

    badgesWrappedProxyV1.initialize("Badges", "BADGES", "0.1.0", contractOwner, address(specDataHolderProxy));
    raftWrappedProxyV1.initialize(contractOwner, "Raft", "RAFT");
    specDataHolderWrappedProxyV1.initialize(address(raftProxy), contractOwner);

    specDataHolderWrappedProxyV1.setBadgesAddress(address(badgesProxy));

    vm.label(passiveAddress, "passive");
  }

  // // helper function
  function createRaftAndRegisterSpec() internal returns (uint256) {
    address to = raftHolderAddress;
    address zeroAddress = address(0);

    vm.expectEmit(true, true, true, false);
    uint256 raftTokenId = raftWrappedProxyV1.mint(to, specUri);
    emit Transfer(zeroAddress, to, raftTokenId);

    assertEq(raftTokenId, 1);
    assertEq(raftWrappedProxyV1.balanceOf(to), 1);
    vm.prank(to);
    badgesWrappedProxyV1.createSpec(specUri, raftTokenId);
    assertEq(specDataHolderWrappedProxyV1.isSpecRegistered(specUri), true);
    return raftTokenId;
  }

  // // helper function
  function getSignature(address active, uint256 passive) internal returns (bytes memory) {
    bytes32 hash = badgesWrappedProxyV1.getAgreementHash(active, vm.addr(passive), specUri);
    // passive is always the one signing away permission for the active party to do something
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passive, hash);
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
    vm.expectRevert(bytes(errBalanceOfNotValidOwner));
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
    vm.expectRevert(bytes(errNotOwner));
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
    vm.expectRevert(bytes(errNotOwner));
    badgesWrappedProxyV1.transferOwnership(randomAddress);
  }

  // // CREATE SPEC TESTS

  function testCreateSpecAsNonRaftOwner() public {
    address to = address(this);
    address zeroAddress = address(0);

    vm.expectEmit(true, true, true, false);
    uint256 raftTokenId = raftWrappedProxyV1.mint(to, specUri);
    emit Transfer(zeroAddress, to, raftTokenId);

    assertEq(raftTokenId, 1);
    assertEq(raftWrappedProxyV1.balanceOf(to), 1);

    address randomAddress = vm.addr(randomPrivateKey);
    vm.prank(randomAddress);

    vm.expectRevert(bytes(errNotRaftOwner));
    badgesWrappedProxyV1.createSpec(specUri, raftTokenId);
  }

  // can't test this one with fuzzing because the owner is set in the "setup"
  // function above, so replacing "to" with "fuzzAddress" will always fail
  function testCreateSpecTwice() public {
    address to = address(this);
    address zeroAddress = address(0);

    vm.expectEmit(true, true, true, false);
    uint256 raftTokenId = raftWrappedProxyV1.mint(to, specUri);
    emit Transfer(zeroAddress, to, raftTokenId);
    assertEq(raftTokenId, 1);
    assertEq(raftWrappedProxyV1.balanceOf(to), 1);
    badgesWrappedProxyV1.createSpec(specUri, raftTokenId);
    vm.expectRevert(bytes(errSpecAlreadyRegistered));
    badgesWrappedProxyV1.createSpec(specUri, raftTokenId);
  }

  function testSenderIsntRaftOwner() public {
    address to = address(this);
    address zeroAddress = address(0);

    vm.expectEmit(true, true, true, false);
    uint256 raftTokenId = raftWrappedProxyV1.mint(to, specUri);
    emit Transfer(zeroAddress, to, raftTokenId);
    assertEq(raftTokenId, 1);
    assertEq(raftWrappedProxyV1.balanceOf(to), 1);
    vm.prank(address(0));
    vm.expectRevert(bytes(errNotRaftOwner));
    badgesWrappedProxyV1.createSpec(specUri, raftTokenId);
  }

  // TODO: write test for a non-owner calling transferOwnership
  // tricky because we need to call a proxy to do this

  // TAKE TESTS
  // happy path
  function testBalanceIncreaseAfterTake() public returns (uint256, uint256) {
    address active = claimantAddress;
    address passive = raftHolderAddress;

    uint256 raftTokenId = createRaftAndRegisterSpec();

    bytes memory signature = getSignature(active, raftHolderPrivateKey);
    vm.expectEmit(true, true, true, false);
    vm.prank(active);
    uint256 tokenId = badgesWrappedProxyV1.take(passive, specUri, signature);

    address zeroAddress = address(0);
    emit Transfer(zeroAddress, active, tokenId);

    assertEq(badgesWrappedProxyV1.balanceOf(active), 1);
    assertEq(badgesWrappedProxyV1.tokenURI(tokenId), specUri);
    assertEq(badgesWrappedProxyV1.ownerOf(tokenId), active);
    return (raftTokenId, tokenId);
  }

  function testTakeWithBadTokenUri() public {
    address active = claimantAddress;

    bytes32 hash = badgesWrappedProxyV1.getAgreementHash(active, vm.addr(raftHolderPrivateKey), badTokenUri);
    // passive is always the one signing away permission for the active party to do something
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(raftHolderPrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    // errors with this because we check for a valid spec URI before validating the signature
    vm.expectRevert(bytes(errInvalidSig));
    badgesWrappedProxyV1.take(passiveAddress, specUri, signature);
  }

  function testTakeWithUnauthorizedRaftHolder() public {
    address active = claimantAddress;
    createRaftAndRegisterSpec();

    bytes memory signature = getSignature(active, raftHolderPrivateKey);

    address unauthorizedSender = address(0);

    vm.expectRevert(bytes(errInvalidSig));
    badgesWrappedProxyV1.take(unauthorizedSender, specUri, signature);
  }

  function testGiveWithUnauthorizedRaftHolder() public {
    address active = raftHolderAddress;
    createRaftAndRegisterSpec();

    bytes memory signature = getSignature(active, raftHolderPrivateKey);

    address unauthorizedSender = address(0);

    vm.expectRevert(bytes(errInvalidSig));
    badgesWrappedProxyV1.give(unauthorizedSender, specUri, signature);
  }

  function testTakeAndUnequipAndRetake() public {
    address active = claimantAddress;
    address passive = raftHolderAddress;
    (, uint256 tokenId) = testBalanceIncreaseAfterTake();

    vm.expectEmit(true, true, true, false);
    vm.prank(active);
    badgesWrappedProxyV1.unequip(tokenId);
    address zeroAddress = address(0);

    emit Transfer(active, zeroAddress, tokenId);
    assertEq(badgesWrappedProxyV1.balanceOf(active), 0);

    bytes memory signature = getSignature(active, raftHolderPrivateKey);
    vm.prank(active);

    vm.expectEmit(true, true, true, false);
    uint256 tokenId2 = badgesWrappedProxyV1.take(passive, specUri, signature);
    emit Transfer(zeroAddress, active, tokenId);

    assertEq(badgesWrappedProxyV1.balanceOf(active), 1);
    assertEq(badgesWrappedProxyV1.tokenURI(tokenId2), specUri);
    assertEq(badgesWrappedProxyV1.ownerOf(tokenId2), active);
  }

  // how was this ever passing???
  function testTakeWithAlreadyUsedVoucher() public {
    address active = claimantAddress;
    address passive = raftHolderAddress;
    testBalanceIncreaseAfterTake();

    bytes memory signature = getSignature(active, raftHolderPrivateKey);
    vm.prank(active);

    vm.expectRevert(bytes(tokenExistsErr));
    badgesWrappedProxyV1.take(passive, specUri, signature);
  }

  function testPreventTakingToSelf() public {
    address to = address(this);
    bytes memory signature;

    vm.expectRevert(bytes(errCannotTakeFromSelf));
    badgesWrappedProxyV1.take(to, specUri, signature);
  }

  // GIVE TESTS
  function testBalanceIncreaseAfterGive() public {
    createRaftAndRegisterSpec();
    address active = raftHolderAddress;
    address passive = passiveAddress;

    bytes32 hash = badgesWrappedProxyV1.getAgreementHash(active, passive, specUri);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);
    vm.prank(active);
    uint256 tokenId = badgesWrappedProxyV1.give(passive, specUri, signature);
    assertEq(badgesWrappedProxyV1.balanceOf(passive), 1);
    assertEq(badgesWrappedProxyV1.tokenURI(tokenId), specUri);
    assertEq(badgesWrappedProxyV1.ownerOf(tokenId), passive);
  }

  function testGiveWithDifferentTokenURI(string memory falseTokenUri) public {
    createRaftAndRegisterSpec();

    address active = raftHolderAddress;
    address passive = passiveAddress;

    bytes32 hash = badgesWrappedProxyV1.getAgreementHash(active, passive, falseTokenUri);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    vm.expectRevert(bytes(errInvalidSig));
    vm.prank(active);

    uint256 tokenId = badgesWrappedProxyV1.give(passive, specUri, signature);
    assertEq(0, tokenId);
  }

  function testGiveWithUnauthorizedSender() public {
    createRaftAndRegisterSpec();
    address from = raftHolderAddress;
    address to = passiveAddress;
    address randomAddress = vm.addr(randomPrivateKey);
    vm.prank(randomAddress);
    bytes32 hash = badgesWrappedProxyV1.getAgreementHash(from, to, specUri);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);
    vm.expectRevert(bytes(errInvalidSig));
    vm.prank(from);

    uint256 tokenId = badgesWrappedProxyV1.give(randomAddress, specUri, signature);
    assertEq(0, tokenId);
  }

  function testGiveAndUnequipAndRegive() public {
    createRaftAndRegisterSpec();
    address from = raftHolderAddress;
    address to = passiveAddress;

    bytes32 hash = badgesWrappedProxyV1.getAgreementHash(from, to, specUri);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);
    vm.expectEmit(true, true, true, false);
    vm.prank(from);
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
    address from = raftHolderAddress;
    address to = passiveAddress;

    bytes32 hash = badgesWrappedProxyV1.getAgreementHash(from, to, specUri);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);
    vm.prank(from);
    badgesWrappedProxyV1.give(to, specUri, signature);

    vm.expectRevert(bytes(tokenExistsErr));
    vm.prank(from);
    badgesWrappedProxyV1.give(to, specUri, signature);
  }

  function testPreventGivingToSelf() public {
    createRaftAndRegisterSpec();

    address active = raftHolderAddress;
    bytes memory signature = getSignature(active, passivePrivateKey);

    vm.prank(active);
    vm.expectRevert(bytes(errCannotGiveToSelf));
    badgesWrappedProxyV1.give(active, specUri, signature);
  }

  // UNEQUIP TESTS
  function testBalanceDecreaseAfterUnequip() public {
    address active = claimantAddress;
    (, uint256 tokenId) = testBalanceIncreaseAfterTake();

    vm.expectEmit(true, true, true, false);
    vm.prank(active);
    badgesWrappedProxyV1.unequip(tokenId);

    address zeroAddress = address(0);
    emit Transfer(active, zeroAddress, tokenId);
    assertEq(badgesWrappedProxyV1.balanceOf(active), 0);
  }

  function testVoucherHashIdsWithUnequip() public {
    address zeroAddress = address(0);

    address active = claimantAddress;
    (, uint256 tokenId) = testBalanceIncreaseAfterTake();

    // uint256 voucherIdAfterTake = badgesWrappedProxyV1.getVoucherHash(tokenId);
    // assertTrue(voucherIdAfterTake != 0);

    vm.expectEmit(true, true, true, false);
    vm.prank(active);
    badgesWrappedProxyV1.unequip(tokenId);
    emit Transfer(active, zeroAddress, tokenId);
    assertEq(badgesWrappedProxyV1.balanceOf(active), 0);

    // uint256 voucherIdAfterUnequip = badgesWrappedProxyV1.getVoucherHash(tokenId);
    // assertTrue(voucherIdAfterUnequip == 0);
  }

  function testUnequippingAsNonAuthorizedAccount() public {
    address active = address(this);
    address passive = raftHolderAddress;

    address zeroAddress = address(0);
    bytes memory signature = getSignature(active, raftHolderPrivateKey);

    createRaftAndRegisterSpec();
    vm.expectEmit(true, true, true, false);
    uint256 tokenId = badgesWrappedProxyV1.take(passive, specUri, signature);
    emit Transfer(zeroAddress, active, tokenId);

    assertEq(badgesWrappedProxyV1.ownerOf(tokenId), active);
    assertEq(badgesWrappedProxyV1.tokenURI(tokenId), specUri);

    vm.prank(zeroAddress);
    vm.expectRevert(bytes(errUnequipSenderNotOwner));
    badgesWrappedProxyV1.unequip(tokenId);
  }

  function testUnequippingNonExistentTokenId() public {
    address active = address(this);
    address passive = raftHolderAddress;

    address zeroAddress = address(0);
    bytes memory signature = getSignature(active, raftHolderPrivateKey);

    createRaftAndRegisterSpec();
    vm.expectEmit(true, true, true, false);
    uint256 tokenId = badgesWrappedProxyV1.take(passive, specUri, signature);
    emit Transfer(zeroAddress, active, tokenId);

    assertEq(badgesWrappedProxyV1.ownerOf(tokenId), active);
    assertEq(badgesWrappedProxyV1.tokenURI(tokenId), specUri);

    vm.expectRevert(bytes(tokenDoesntExistErr));
    badgesWrappedProxyV1.unequip(1337);
  }

  function testRevokingBadge() public {
    (uint256 raftTokenId, uint256 tokenId) = testBalanceIncreaseAfterTake();

    assertEq(badgesWrappedProxyV1.isBadgeValid(tokenId), true);
    vm.prank(raftHolderAddress);
    badgesWrappedProxyV1.revokeBadge(raftTokenId, tokenId, 1);
    assertEq(badgesWrappedProxyV1.isBadgeValid(tokenId), false);
  }

  function testReinstatingBadge() public {
    (uint256 raftTokenId, uint256 tokenId) = testBalanceIncreaseAfterTake();

    assertEq(badgesWrappedProxyV1.isBadgeValid(tokenId), true);

    vm.prank(raftHolderAddress);
    badgesWrappedProxyV1.revokeBadge(raftTokenId, tokenId, 1);
    assertEq(badgesWrappedProxyV1.isBadgeValid(tokenId), false);

    vm.prank(raftHolderAddress);
    badgesWrappedProxyV1.reinstateBadge(raftTokenId, tokenId);
    assertEq(badgesWrappedProxyV1.isBadgeValid(tokenId), true);
  }

  function testIsBadgeValid() public {
    (uint256 raftTokenId, uint256 tokenId) = testBalanceIncreaseAfterTake();

    assertEq(badgesWrappedProxyV1.isBadgeValid(tokenId), true);
    vm.prank(raftHolderAddress);
    badgesWrappedProxyV1.revokeBadge(raftTokenId, tokenId, 1);
    assertEq(badgesWrappedProxyV1.isBadgeValid(tokenId), false);
  }

  function testRefreshMetadata() public {
    createRaftAndRegisterSpec();

    vm.expectEmit(true, false, false, false);

    emit RefreshMetadata(specUris, msg.sender);
    badgesWrappedProxyV1.refreshMetadata(specUris);
  }

  function testTakeValidSigTransferredRaftToken() public {
    address active = claimantAddress;
    address zeroAddress = address(0);

    vm.expectEmit(true, true, true, false);
    // mint raft
    uint256 raftTokenId = raftWrappedProxyV1.mint(raftHolderAddress, specUri);
    emit Transfer(zeroAddress, raftHolderAddress, raftTokenId);

    assertEq(raftTokenId, 1);
    assertEq(raftWrappedProxyV1.balanceOf(raftHolderAddress), 1);
    // raft holder registers spec
    vm.prank(raftHolderAddress);
    badgesWrappedProxyV1.createSpec(specUri, raftTokenId);
    assertEq(specDataHolderWrappedProxyV1.isSpecRegistered(specUri), true);
    // create "valid" signature
    bytes32 hash = badgesWrappedProxyV1.getAgreementHash(active, raftHolderAddress, specUri);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(raftHolderPrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);
    // transfer raft away from owner
    address randomAddress = vm.addr(randomPrivateKey);
    vm.prank(raftHolderAddress);

    raftWrappedProxyV1.approve(randomAddress, raftTokenId);
    vm.prank(raftHolderAddress);

    raftWrappedProxyV1.transferFrom(raftHolderAddress, randomAddress, raftTokenId);
    assertEq(raftWrappedProxyV1.balanceOf(randomAddress), 1);

    // try to take with signature
    vm.prank(active);
    vm.expectRevert(bytes(errTakeUnauthorized));
    badgesWrappedProxyV1.take(raftHolderAddress, specUri, signature);
    // expect failure
  }

  function testGiveValidSigTransferredRaftToken() public {
    address passive = passiveAddress;
    address zeroAddress = address(0);

    vm.expectEmit(true, true, true, false);
    // mint raft
    uint256 raftTokenId = raftWrappedProxyV1.mint(raftHolderAddress, specUri);
    emit Transfer(zeroAddress, raftHolderAddress, raftTokenId);

    assertEq(raftTokenId, 1);
    assertEq(raftWrappedProxyV1.balanceOf(raftHolderAddress), 1);
    // raft holder registers spec
    vm.prank(raftHolderAddress);
    badgesWrappedProxyV1.createSpec(specUri, raftTokenId);
    assertEq(specDataHolderWrappedProxyV1.isSpecRegistered(specUri), true);
    // create "valid" signature
    bytes32 hash = badgesWrappedProxyV1.getAgreementHash(raftHolderAddress, passive, specUri);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);
    // transfer raft away from owner
    address randomAddress = vm.addr(randomPrivateKey);
    vm.prank(raftHolderAddress);

    raftWrappedProxyV1.approve(randomAddress, raftTokenId);
    vm.prank(raftHolderAddress);

    raftWrappedProxyV1.transferFrom(raftHolderAddress, randomAddress, raftTokenId);
    assertEq(raftWrappedProxyV1.balanceOf(randomAddress), 1);

    // try to give
    // expect failure
    vm.prank(raftHolderAddress);
    vm.expectRevert(bytes(errGiveUnauthorized));
    badgesWrappedProxyV1.give(passive, specUri, signature);
  }

  function testSafeCheckMerkleAgreementShouldPassForValidClaimants() public {
    address from = passiveAddress;
    address to = 0x0000000000000000000000000000000000000002;

    Merkle m = new Merkle();
    bytes32[] memory data = _getTestDataWithDistinctValues();
    bytes32 root = m.getRoot(data);

    bytes32[] memory proof = m.getProof(data, 2); // proofs for valid claimant
    bytes memory signature = _getSignatureForMerkleAgreementHash(from, specUri, root);
    // vm.prank(to); // valid claimant
    badgesWrappedProxyV1.safeCheckMerkleAgreement(from, to, specUri, signature, root, proof);
  }

  function testSafeCheckMerkleAgreementShouldFailForInvalidProofs() public {
    address from = passiveAddress;
    address to = claimantAddress;

    Merkle m = new Merkle();
    bytes32[] memory data = _getTestDataWithDistinctValues();
    bytes32 root = m.getRoot(data);
    bytes32[] memory proof = m.getProof(data, 0);
    // bytes32 validClaimant = bytes32(uint256(uint160(0x0000000000000000000000000000000000000000)) << 96);

    vm.prank(0x0000000000000000000000000000000000000003); // valid claimant
    bytes memory signature = _getSignatureForMerkleAgreementHash(from, specUri, root);

    vm.prank(0x0000000000000000000000000000000000000009); // invalid claimant
    vm.expectRevert(bytes(errMerkleInvalidLeaf));
    badgesWrappedProxyV1.safeCheckMerkleAgreement(from, to, specUri, signature, root, proof);

    bytes32[] memory invalidProof = new bytes32[](1);
    vm.expectRevert(bytes(errMerkleInvalidLeaf));
    badgesWrappedProxyV1.safeCheckMerkleAgreement(from, to, specUri, signature, root, invalidProof);

    bytes32 invalidRoot = bytes32("invalid_root");
    vm.expectRevert(bytes(errMerkleInvalidSignature));
    badgesWrappedProxyV1.safeCheckMerkleAgreement(from, to, specUri, signature, invalidRoot, proof);
  }

  function _getTestDataWithDistinctValues() private pure returns (bytes32[] memory data) {
    data = new bytes32[](6);
    data[0] = keccak256(abi.encodePacked(0x0000000000000000000000000000000000000000));
    data[1] = keccak256(abi.encodePacked(0x0000000000000000000000000000000000000001));
    data[2] = keccak256(abi.encodePacked(0x0000000000000000000000000000000000000002));
    data[3] = keccak256(abi.encodePacked(0x0000000000000000000000000000000000000003));
    data[4] = keccak256(abi.encodePacked(0x0000000000000000000000000000000000000004));
    data[5] = keccak256(abi.encodePacked(0x0000000000000000000000000000000000000004));
  }

  function _getSignatureForMerkleAgreementHash(
    address issuer,
    string storage uri,
    bytes32 root
  ) private returns (bytes memory signature) {
    bytes32 hash = badgesWrappedProxyV1.getMerkleAgreementHash(issuer, uri, root);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    signature = abi.encodePacked(r, s, v);
  }
}
