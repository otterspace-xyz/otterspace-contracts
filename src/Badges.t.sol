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
  constructor(address _implementation, bytes memory _data)
    ERC1967Proxy(_implementation, _data)
  {}
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
  uint256 passivePrivateKey =
    0xad54bdeade5537fb0a553190159783e45d02d316a992db05cbed606d3ca36b39;

  uint256 randomPrivateKey =
    0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

  uint256 raftHolderPrivateKey =
    0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
  address raftHolderAddress =
    vm.addr(0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d);

  uint256 claimantPrivateKey =
    0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;
  address claimantAddress =
    vm.addr(0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a);

  string[] specUris = ["spec1", "spec2"];
  string badTokenUri = "bad token uri";

  string err721InvalidTokenId = "ERC721: invalid token ID";
  string errBadgeAlreadyRevoked = "revokeBadge: badge already revoked";
  string errBalanceOfNotValidOwner =
    "balanceOf: address(0) is not a valid owner";
  string errGiveToManyArrayMismatch =
    "giveToMany: recipients and signatures length mismatch";
  string errInvalidSig = "safeCheckAgreement: invalid signature";
  string errOnlyBadgesContract = "onlyBadgesContract: unauthorized";
  string errNoSpecUris = "refreshMetadata: no spec uris provided";
  string errNotOwner = "Ownable: caller is not the owner";
  string errNotRaftOwner = "onlyRaftOwner: unauthorized";
  string errCreateSpecUnauthorized = "createSpec: unauthorized";
  string errNotRevoked = "reinstateBadge: badge not revoked";
  string errSafeCheckUsed = "safeCheckAgreement: already used";
  string errSpecAlreadyRegistered = "createSpec: spec already registered";
  string errSpecNotRegistered = "mint: spec is not registered";
  string errGiveUnauthorized = "give: unauthorized";
  string errUnequipSenderNotOwner = "unequip: sender must be owner";
  string errTakeUnauthorized = "take: unauthorized";
  string errMerkleInvalidLeaf = "safeCheckMerkleAgreement: invalid leaf";
  string errMerkleInvalidSignature =
    "safeCheckMerkleAgreement: invalid signature";
  string errTokenDoesntExist = "tokenExists: token doesn't exist";
  string errTokenExists = "mint: tokenID exists";
  string errRevokeUnauthorized = "revokeBadge: unauthorized";
  string errReinstateUnauthorized = "reinstateBadge: unauthorized";
  string errRequestedBadgeUnauthorized = "giveRequestedBadge: unauthorized";

  string specUri = "some spec uri";

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );
  event RefreshMetadata(string[] specUris, address sender);

  function setUp() public {
    address contractOwner = address(this);

    badgesImplementationV1 = new Badges();
    specDataHolderImplementationV1 = new SpecDataHolder();
    raftImplementationV1 = new Raft();

    badgesProxy = new UUPSProxy(address(badgesImplementationV1), "");
    raftProxy = new UUPSProxy(address(raftImplementationV1), "");
    specDataHolderProxy = new UUPSProxy(
      address(specDataHolderImplementationV1),
      ""
    );

    badgesWrappedProxyV1 = Badges(address(badgesProxy));
    raftWrappedProxyV1 = Raft(address(raftProxy));
    specDataHolderWrappedProxyV1 = SpecDataHolder(address(specDataHolderProxy));

    badgesWrappedProxyV1.initialize(
      "Badges",
      "BADGES",
      "0.1.0",
      contractOwner,
      address(specDataHolderProxy)
    );
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
  function getSignature(address active, uint256 passive)
    internal
    returns (bytes memory)
  {
    bytes32 hash = badgesWrappedProxyV1.getAgreementHash(
      active,
      vm.addr(passive),
      specUri
    );
    // passive is always the one signing away permission for the active party to do something
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passive, hash);
    bytes memory signature = abi.encodePacked(r, s, v);
    return signature;
  }

  function testIERC721Metadata() public {
    assertTrue(
      badgesWrappedProxyV1.supportsInterface(type(IERC721Metadata).interfaceId)
    );
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

  function testCreateSpecAsRaftOwner() public {
    address raftOwner = address(this);
    uint256 raftTokenId = raftWrappedProxyV1.mint(raftOwner, specUri);

    vm.prank(raftOwner);
    badgesWrappedProxyV1.createSpec(specUri, raftTokenId);
  }

  function testCreateSpecAsAdmin() public {
    address raftOwner = address(this);
    address admin = address(123);
    uint256 raftTokenId = raftWrappedProxyV1.mint(raftOwner, specUri);
    raftWrappedProxyV1.setAdmin(raftTokenId, admin, true);

    vm.prank(admin);
    badgesWrappedProxyV1.createSpec(specUri, raftTokenId);
  }

  function testCreateSpecAsDeactivatedAdmin() public {
    address raftOwner = address(this);
    address admin = address(123);
    uint256 raftTokenId = raftWrappedProxyV1.mint(raftOwner, specUri);
    raftWrappedProxyV1.setAdmin(raftTokenId, admin, false);

    vm.prank(admin);
    vm.expectRevert(bytes(errCreateSpecUnauthorized));
    badgesWrappedProxyV1.createSpec(specUri, raftTokenId);
  }

  function testCreateSpecAsUnauthorizedAccount() public {
    address to = address(this);
    address randomAddress = vm.addr(randomPrivateKey);
    uint256 raftTokenId = raftWrappedProxyV1.mint(to, specUri);

    vm.prank(randomAddress);
    vm.expectRevert(bytes(errCreateSpecUnauthorized));
    badgesWrappedProxyV1.createSpec(specUri, raftTokenId);
  }

  // can't test this one with fuzzing because the owner is set in the "setup"
  // function above, so replacing "to" with "fuzzAddress" will always fail
  function testCreatingWithExistingSpecUriShouldRevert() public {
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

  // TODO: write test for a non-owner calling transferOwnership
  // tricky because we need to call a proxy to do this

  // TAKE TESTS
  // happy path
  function testTake() public returns (uint256, uint256) {
    address active = claimantAddress;
    address passive = raftHolderAddress;
    uint256 raftTokenId = createRaftAndRegisterSpec();
    bytes memory signature = getSignature(active, raftHolderPrivateKey);

    vm.prank(active);
    uint256 tokenId = badgesWrappedProxyV1.take(passive, specUri, signature);

    assertEq(badgesWrappedProxyV1.balanceOf(active), 1);
    assertEq(badgesWrappedProxyV1.tokenURI(tokenId), specUri);
    assertEq(badgesWrappedProxyV1.ownerOf(tokenId), active);

    return (raftTokenId, tokenId);
  }

  function testTakeAfterIssuerTransferredRaftShouldFail()
    public
    returns (uint256, uint256)
  {
    uint256 raftTokenId = createRaftAndRegisterSpec();
    bytes memory signature = getSignature(
      claimantAddress,
      raftHolderPrivateKey
    );
    address newRaftHolder = address(123);

    // transfer raft to new holder
    vm.prank(raftHolderAddress);
    raftWrappedProxyV1.transferFrom(
      raftHolderAddress,
      newRaftHolder,
      raftTokenId
    );

    vm.prank(claimantAddress);
    vm.expectRevert(bytes(errTakeUnauthorized));
    uint256 tokenId = badgesWrappedProxyV1.take(
      raftHolderAddress,
      specUri,
      signature
    );

    assertEq(badgesWrappedProxyV1.balanceOf(claimantAddress), 0);

    return (raftTokenId, tokenId);
  }

  function testTakeAfterIssuerTransferredRaftAndSetPreviousHolderAsAdmin()
    public
    returns (uint256, uint256)
  {
    uint256 raftTokenId = createRaftAndRegisterSpec();
    bytes memory signature = getSignature(
      claimantAddress,
      raftHolderPrivateKey
    );
    address newRaftHolder = address(123);

    // transfer raft to new holder
    vm.prank(raftHolderAddress);
    raftWrappedProxyV1.transferFrom(
      raftHolderAddress,
      newRaftHolder,
      raftTokenId
    );

    // mark the old holder as admin
    vm.prank(newRaftHolder);
    raftWrappedProxyV1.setAdmin(raftTokenId, raftHolderAddress, true);

    vm.prank(claimantAddress);
    uint256 tokenId = badgesWrappedProxyV1.take(
      raftHolderAddress,
      specUri,
      signature
    );

    assertEq(badgesWrappedProxyV1.balanceOf(claimantAddress), 1);
    assertEq(badgesWrappedProxyV1.tokenURI(tokenId), specUri);
    assertEq(badgesWrappedProxyV1.ownerOf(tokenId), claimantAddress);

    return (raftTokenId, tokenId);
  }

  function testTakeWithSigFromUnauthorizedActor() public {
    address active = claimantAddress;
    address passive = raftHolderAddress;
    uint256 badActorPrivateKey = 123;
    createRaftAndRegisterSpec();
    bytes memory signature = getSignature(active, badActorPrivateKey);

    vm.prank(active);
    vm.expectRevert(bytes(errInvalidSig));
    uint256 tokenId = badgesWrappedProxyV1.take(passive, specUri, signature);

    assertEq(tokenId, 0);
    assertEq(badgesWrappedProxyV1.balanceOf(active), 0);
  }

  function testTakeWithUnregisteredSpec() public {
    address passive = raftHolderAddress;
    address zeroAddress = address(0);
    address active = claimantAddress;

    vm.expectEmit(true, true, true, false);
    uint256 raftTokenId = raftWrappedProxyV1.mint(passive, specUri);
    emit Transfer(zeroAddress, passive, raftTokenId);

    assertEq(raftTokenId, 1);
    assertEq(raftWrappedProxyV1.balanceOf(passive), 1);

    // normally we would register the spec here
    bytes memory signature = getSignature(active, raftHolderPrivateKey);
    vm.prank(active);
    // but we didn't, so we'll get this error when we try to "take"
    // because when we look up the spec that's associated with this raft, which doesn't exist
    vm.expectRevert(bytes(err721InvalidTokenId));
    badgesWrappedProxyV1.take(passive, specUri, signature);
  }

  function testTakeWithBadTokenUri() public {
    address active = claimantAddress;

    bytes32 hash = badgesWrappedProxyV1.getAgreementHash(
      active,
      vm.addr(raftHolderPrivateKey),
      badTokenUri
    );
    // passive is always the one signing away permission for the active party to do something
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(raftHolderPrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    // errors with this because we check for a valid spec URI before validating the signature
    vm.expectRevert(bytes(errInvalidSig));
    badgesWrappedProxyV1.take(passiveAddress, specUri, signature);
  }

  function testTakeWithUnauthorizedClaimant() public {
    address active = claimantAddress;
    createRaftAndRegisterSpec();

    bytes memory signature = getSignature(active, raftHolderPrivateKey);

    address unauthorizedClaimant = address(0);

    vm.expectRevert(bytes(errInvalidSig));
    badgesWrappedProxyV1.take(unauthorizedClaimant, specUri, signature);
  }

  function testTakeAndUnequipAndRetake() public {
    address active = claimantAddress;
    address passive = raftHolderAddress;
    (, uint256 tokenId) = testTake();

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

  function testTakeWithAlreadyUsedVoucher() public {
    address active = claimantAddress;
    address passive = raftHolderAddress;
    testTake();

    bytes memory signature = getSignature(active, raftHolderPrivateKey);
    vm.prank(active);

    vm.expectRevert(bytes(errTokenExists));
    badgesWrappedProxyV1.take(passive, specUri, signature);
  }

  // REQUEST BADGE TESTS
  function testGiveRequestedBadgeAsRaftHolder() public {
    createRaftAndRegisterSpec();

    bytes32 hash = badgesWrappedProxyV1.getRequestHash(
      claimantAddress,
      specUri
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(claimantPrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    vm.prank(raftHolderAddress);
    uint256 tokenId = badgesWrappedProxyV1.giveRequestedBadge(
      claimantAddress,
      specUri,
      signature
    );
    assertEq(badgesWrappedProxyV1.balanceOf(claimantAddress), 1);
    assertEq(badgesWrappedProxyV1.tokenURI(tokenId), specUri);
    assertEq(badgesWrappedProxyV1.ownerOf(tokenId), claimantAddress);
  }

  function testGiveRequestedBadgeAsAdmin() public {
    uint256 raftTokenId = createRaftAndRegisterSpec();
    address admin = address(123);

    vm.prank(raftHolderAddress);
    raftWrappedProxyV1.setAdmin(raftTokenId, admin, true);

    bytes32 hash = badgesWrappedProxyV1.getRequestHash(
      claimantAddress,
      specUri
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(claimantPrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    vm.prank(admin);
    uint256 tokenId = badgesWrappedProxyV1.giveRequestedBadge(
      claimantAddress,
      specUri,
      signature
    );
    assertEq(badgesWrappedProxyV1.balanceOf(claimantAddress), 1);
    assertEq(badgesWrappedProxyV1.tokenURI(tokenId), specUri);
    assertEq(badgesWrappedProxyV1.ownerOf(tokenId), claimantAddress);
  }

  function testGiveRequestedBadgeAsUnauthorizedActor() public {
    createRaftAndRegisterSpec();

    bytes32 hash = badgesWrappedProxyV1.getRequestHash(
      claimantAddress,
      specUri
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(claimantPrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    address unauthorizedAccount = address(123456);

    vm.prank(unauthorizedAccount);
    vm.expectRevert(bytes(errRequestedBadgeUnauthorized));
    badgesWrappedProxyV1.giveRequestedBadge(
      claimantAddress,
      specUri,
      signature
    );
    assertEq(badgesWrappedProxyV1.balanceOf(claimantAddress), 0);
  }

  // GIVE TESTS
  function testBalanceIncreaseAfterGive() public {
    createRaftAndRegisterSpec();
    address active = raftHolderAddress;
    address passive = passiveAddress;

    bytes32 hash = badgesWrappedProxyV1.getAgreementHash(
      active,
      passive,
      specUri
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);
    vm.prank(active);
    uint256 tokenId = badgesWrappedProxyV1.give(passive, specUri, signature);
    assertEq(badgesWrappedProxyV1.balanceOf(passive), 1);
    assertEq(badgesWrappedProxyV1.tokenURI(tokenId), specUri);
    assertEq(badgesWrappedProxyV1.ownerOf(tokenId), passive);
  }

  function testGiveCalledByNonOwner() public {
    createRaftAndRegisterSpec();
    address active = raftHolderAddress;
    address passive = passiveAddress;

    bytes32 hash = badgesWrappedProxyV1.getAgreementHash(
      active,
      passive,
      specUri
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    address randomAddress = vm.addr(123);
    vm.prank(randomAddress);
    vm.expectRevert(bytes(errGiveUnauthorized));
    badgesWrappedProxyV1.give(passive, specUri, signature);
  }

  function testGiveWithDifferentTokenURI(string memory falseTokenUri) public {
    createRaftAndRegisterSpec();

    address active = raftHolderAddress;
    address passive = passiveAddress;

    bytes32 hash = badgesWrappedProxyV1.getAgreementHash(
      active,
      passive,
      falseTokenUri
    );
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

    uint256 tokenId = badgesWrappedProxyV1.give(
      randomAddress,
      specUri,
      signature
    );
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

    vm.expectRevert(bytes(errTokenExists));
    vm.prank(from);
    badgesWrappedProxyV1.give(to, specUri, signature);
  }

  // UNEQUIP TESTS
  function testBalanceDecreaseAfterUnequip() public {
    address active = claimantAddress;
    (, uint256 tokenId) = testTake();

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
    (, uint256 tokenId) = testTake();

    vm.expectEmit(true, true, true, false);
    vm.prank(active);
    badgesWrappedProxyV1.unequip(tokenId);
    emit Transfer(active, zeroAddress, tokenId);
    assertEq(badgesWrappedProxyV1.balanceOf(active), 0);
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

    vm.expectRevert(bytes(errTokenDoesntExist));
    badgesWrappedProxyV1.unequip(1337);
  }

  // REVOCATION TESTS
  function testRevokeBadge() public {
    (uint256 raftTokenId, uint256 tokenId) = testTake();

    vm.prank(raftHolderAddress);
    badgesWrappedProxyV1.revokeBadge(raftTokenId, tokenId, 1);

    assertEq(badgesWrappedProxyV1.isBadgeValid(tokenId), false);
  }

  function testRevokeBadgeAsAdmin() public {
    address admin = vm.addr(randomPrivateKey);
    (uint256 raftTokenId, uint256 tokenId) = testTake();

    vm.prank(raftHolderAddress);
    raftWrappedProxyV1.setAdmin(raftTokenId, admin, true);

    vm.prank(admin);
    badgesWrappedProxyV1.revokeBadge(raftTokenId, tokenId, 1);

    assertEq(badgesWrappedProxyV1.isBadgeValid(tokenId), false);
  }

  function testRevokeBadgeThatsAlreadyRevoked() public {
    (uint256 raftTokenId, uint256 tokenId) = testTake();
    assertEq(badgesWrappedProxyV1.isBadgeValid(tokenId), true);

    vm.prank(raftHolderAddress);
    badgesWrappedProxyV1.revokeBadge(raftTokenId, tokenId, 1);
    assertEq(badgesWrappedProxyV1.isBadgeValid(tokenId), false);

    vm.prank(raftHolderAddress);
    vm.expectRevert(bytes(errBadgeAlreadyRevoked));
    badgesWrappedProxyV1.revokeBadge(raftTokenId, tokenId, 1);
  }

  function testRevokeBadgeWithInvalidTokenId() public {
    (uint256 raftTokenId, ) = testTake();
    uint256 invalidTokenId = 123;

    vm.prank(raftHolderAddress);
    vm.expectRevert(bytes(errTokenDoesntExist));
    badgesWrappedProxyV1.revokeBadge(raftTokenId, invalidTokenId, 1);
  }

  function testRevokeBadgeAsUnauthorizedAccountShouldError() public {
    (uint256 raftTokenId, uint256 tokenId) = testTake();
    address unauthorizedAccount = address(123);

    assertEq(badgesWrappedProxyV1.isBadgeValid(tokenId), true);

    vm.prank(unauthorizedAccount);
    vm.expectRevert(bytes(errRevokeUnauthorized));
    badgesWrappedProxyV1.revokeBadge(raftTokenId, tokenId, 1);

    assertEq(badgesWrappedProxyV1.isBadgeValid(tokenId), true);
  }

  // REINSTATE tests

  function testReinstatingBadge() public {
    (uint256 raftTokenId, uint256 tokenId) = testTake();

    assertEq(badgesWrappedProxyV1.isBadgeValid(tokenId), true);

    vm.prank(raftHolderAddress);
    badgesWrappedProxyV1.revokeBadge(raftTokenId, tokenId, 1);
    assertEq(badgesWrappedProxyV1.isBadgeValid(tokenId), false);

    vm.prank(raftHolderAddress);
    badgesWrappedProxyV1.reinstateBadge(raftTokenId, tokenId);
    assertEq(badgesWrappedProxyV1.isBadgeValid(tokenId), true);
  }

  function testReinstatingBadgeThatsNotRevoked() public {
    (uint256 raftTokenId, uint256 tokenId) = testTake();

    assertEq(badgesWrappedProxyV1.isBadgeValid(tokenId), true);

    vm.prank(raftHolderAddress);
    vm.expectRevert(bytes(errNotRevoked));

    badgesWrappedProxyV1.reinstateBadge(raftTokenId, tokenId);
  }

  function testReinstateBadgeAsUnauthorizedAccountShouldError() public {
    address unauthorizedAccount = address(123);
    (uint256 raftTokenId, uint256 tokenId) = testTake();

    assertEq(badgesWrappedProxyV1.isBadgeValid(tokenId), true);

    vm.prank(raftHolderAddress);
    badgesWrappedProxyV1.revokeBadge(raftTokenId, tokenId, 1);
    assertEq(badgesWrappedProxyV1.isBadgeValid(tokenId), false);

    vm.prank(unauthorizedAccount);
    vm.expectRevert(bytes(errReinstateUnauthorized));
    badgesWrappedProxyV1.reinstateBadge(raftTokenId, tokenId);

    assertEq(badgesWrappedProxyV1.isBadgeValid(tokenId), false);
  }

  // BADGE VALIDITY TESTS

  function testIsBadgeValid() public {
    (uint256 raftTokenId, uint256 tokenId) = testTake();

    assertEq(badgesWrappedProxyV1.isBadgeValid(tokenId), true);
    vm.prank(raftHolderAddress);
    badgesWrappedProxyV1.revokeBadge(raftTokenId, tokenId, 1);
    assertEq(badgesWrappedProxyV1.isBadgeValid(tokenId), false);
  }

  // REFRESH METADATA TESTS

  function testRefreshMetadata() public {
    createRaftAndRegisterSpec();

    vm.expectEmit(true, false, false, false);

    emit RefreshMetadata(specUris, msg.sender);
    badgesWrappedProxyV1.refreshMetadata(specUris);
  }

  function testRefreshMetadataWithEmptySpecUris() public {
    createRaftAndRegisterSpec();
    vm.expectRevert(bytes(errNoSpecUris));

    string[] memory emptySpecUriArray = new string[](0);
    // will fail when you give it no spec uris
    badgesWrappedProxyV1.refreshMetadata(emptySpecUriArray);
  }

  function testRefreshMetadataAsNonOwner() public {
    createRaftAndRegisterSpec();

    address randomAddress = vm.addr(123);
    vm.prank(randomAddress);
    vm.expectRevert(bytes(errNotOwner));
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
    bytes32 hash = badgesWrappedProxyV1.getAgreementHash(
      active,
      raftHolderAddress,
      specUri
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(raftHolderPrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    // transfer raft away from owner
    address randomAddress = vm.addr(randomPrivateKey);
    vm.prank(raftHolderAddress);

    raftWrappedProxyV1.approve(randomAddress, raftTokenId);
    vm.prank(raftHolderAddress);

    raftWrappedProxyV1.transferFrom(
      raftHolderAddress,
      randomAddress,
      raftTokenId
    );
    assertEq(raftWrappedProxyV1.balanceOf(randomAddress), 1);

    // try to take with signature
    vm.prank(active);
    // expect failure because the "passive" address is not the owner of the raft anymore
    vm.expectRevert(bytes(errTakeUnauthorized));
    badgesWrappedProxyV1.take(raftHolderAddress, specUri, signature);
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
    bytes32 hash = badgesWrappedProxyV1.getAgreementHash(
      raftHolderAddress,
      passive,
      specUri
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);
    // transfer raft away from owner
    address randomAddress = vm.addr(randomPrivateKey);
    vm.prank(raftHolderAddress);

    raftWrappedProxyV1.approve(randomAddress, raftTokenId);
    vm.prank(raftHolderAddress);

    raftWrappedProxyV1.transferFrom(
      raftHolderAddress,
      randomAddress,
      raftTokenId
    );
    assertEq(raftWrappedProxyV1.balanceOf(randomAddress), 1);

    // try to give
    // expect failure
    vm.prank(raftHolderAddress);
    vm.expectRevert(bytes(errGiveUnauthorized));
    badgesWrappedProxyV1.give(passive, specUri, signature);
  }

  function testMerkleHappyPath()
    public
    returns (
      bytes memory signature,
      bytes32 root,
      bytes32[] memory proof,
      uint256 raftTokenId
    )
  {
    address passive = raftHolderAddress;
    address active = 0x0000000000000000000000000000000000000002;

    uint256 raftTokenId = createRaftAndRegisterSpec();
    Merkle m = new Merkle();
    bytes32[] memory data = _getTestDataWithDistinctValues();

    bytes32 root = m.getRoot(data);

    uint256 indexOfClaimant = 2;

    bytes32[] memory proof = m.getProof(data, indexOfClaimant); // proofs for valid claimant

    bytes memory signature = _getSignatureForMerkleAgreementHash(
      passive,
      specUri,
      root
    );
    vm.prank(active); // valid claimant
    badgesWrappedProxyV1.merkleTake(passive, specUri, signature, root, proof);
    assertEq(badgesWrappedProxyV1.balanceOf(active), 1);
    return (signature, root, proof, raftTokenId);
  }

  function testMerkleDoubleTake() public {
    address passive = raftHolderAddress;
    address active = 0x0000000000000000000000000000000000000002;

    // first merkle take
    (
      bytes memory signature,
      bytes32 root,
      bytes32[] memory proof,
      uint256 raftTokenId
    ) = testMerkleHappyPath();

    vm.prank(active);
    vm.expectRevert(bytes(errTokenExists));
    // second merkle take should fail
    badgesWrappedProxyV1.merkleTake(passive, specUri, signature, root, proof);
  }

  function testTakeThenAttemptMerkleTake() public {
    // address passive = raftHolderAddress;
    address active = 0x0000000000000000000000000000000000000002;
    // address active = claimantAddress;
    address passive = raftHolderAddress;

    uint256 raftTokenId = createRaftAndRegisterSpec();

    bytes memory standardTakeSig = getSignature(active, raftHolderPrivateKey);
    vm.expectEmit(true, true, true, false);
    vm.prank(active);
    uint256 tokenId = badgesWrappedProxyV1.take(
      passive,
      specUri,
      standardTakeSig
    );

    address zeroAddress = address(0);
    emit Transfer(zeroAddress, active, tokenId);

    assertEq(badgesWrappedProxyV1.balanceOf(active), 1);
    assertEq(badgesWrappedProxyV1.tokenURI(tokenId), specUri);
    assertEq(badgesWrappedProxyV1.ownerOf(tokenId), active);

    Merkle m = new Merkle();
    bytes32[] memory data = _getTestDataWithDistinctValues();

    bytes32 root = m.getRoot(data);

    uint256 indexOfClaimant = 2;

    bytes32[] memory proof = m.getProof(data, indexOfClaimant);

    bytes memory signature = _getSignatureForMerkleAgreementHash(
      passive,
      specUri,
      root
    );
    vm.prank(active);
    vm.expectRevert(bytes(errTokenExists));
    badgesWrappedProxyV1.merkleTake(passive, specUri, signature, root, proof);
    assertEq(badgesWrappedProxyV1.balanceOf(active), 1);
  }

  function testMerkleClaimantOnTwoTrees() public {
    address passive = raftHolderAddress;
    address active = 0x0000000000000000000000000000000000000002;

    (, , , uint256 raftTokenId) = testMerkleHappyPath();

    /*** Create another spec ***/
    vm.prank(passive);
    badgesWrappedProxyV1.createSpec(specUris[1], raftTokenId);
    assertEq(specDataHolderWrappedProxyV1.isSpecRegistered(specUris[1]), true);
    /*** END Create another spec ***/

    bytes32[] memory tree2 = _getTree2();

    Merkle m = new Merkle();

    bytes32 rootOfTree2 = m.getRoot(tree2);

    uint256 indexOfClaimant = 1;

    bytes32[] memory proofOfTree2 = m.getProof(tree2, indexOfClaimant); // proofs for valid claimant

    bytes memory signatureOfTree2 = _getSignatureForMerkleAgreementHash(
      passive,
      specUris[1],
      rootOfTree2
    );
    vm.prank(active); // valid claimant
    badgesWrappedProxyV1.merkleTake(
      passive,
      specUris[1],
      signatureOfTree2,
      rootOfTree2,
      proofOfTree2
    );
    assertEq(badgesWrappedProxyV1.balanceOf(active), 2);
  }

  function testSafeCheckMerkleAgreementShouldFailForInvalidProofs() public {
    address from = raftHolderAddress;

    uint256 raftTokenId = createRaftAndRegisterSpec();
    Merkle m = new Merkle();
    bytes32[] memory data = _getTestDataWithDistinctValues();
    bytes32 root = m.getRoot(data);

    uint256 indexOfClaimant1 = 1;

    bytes32[] memory proof = m.getProof(data, indexOfClaimant1);

    bytes memory signature = _getSignatureForMerkleAgreementHash(
      from,
      specUri,
      root
    );
    vm.prank(0x0000000000000000000000000000000000000001); // valid claimant
    badgesWrappedProxyV1.merkleTake(from, specUri, signature, root, proof);

    assertEq(
      badgesWrappedProxyV1.balanceOf(
        0x0000000000000000000000000000000000000001
      ),
      1
    );

    bytes32 invalidRoot = bytes32("invalid_root");
    vm.prank(0x0000000000000000000000000000000000000001);
    vm.expectRevert(bytes(errMerkleInvalidSignature));
    // same as previous call but with invalid root
    badgesWrappedProxyV1.merkleTake(
      from,
      specUri,
      signature,
      invalidRoot,
      proof
    );
  }

  function _getTree2() private pure returns (bytes32[] memory data) {
    data = new bytes32[](2);
    data[0] = keccak256(
      abi.encodePacked(0x0000000000000000000000000000000000000001)
    );
    data[1] = keccak256(
      abi.encodePacked(0x0000000000000000000000000000000000000002)
    );
  }

  function _getTestDataWithDistinctValues()
    private
    pure
    returns (bytes32[] memory data)
  {
    data = new bytes32[](6);
    data[0] = keccak256(
      abi.encodePacked(0x0000000000000000000000000000000000000000)
    );
    data[1] = keccak256(
      abi.encodePacked(0x0000000000000000000000000000000000000001)
    );
    data[2] = keccak256(
      abi.encodePacked(0x0000000000000000000000000000000000000002)
    );
    data[3] = keccak256(
      abi.encodePacked(0x0000000000000000000000000000000000000003)
    );
    data[4] = keccak256(
      abi.encodePacked(0x0000000000000000000000000000000000000004)
    );
    data[5] = keccak256(
      abi.encodePacked(0x0000000000000000000000000000000000000004)
    );
  }

  function _getSignatureForMerkleAgreementHash(
    address issuer,
    string storage uri,
    bytes32 root
  ) private returns (bytes memory signature) {
    bytes32 hash = badgesWrappedProxyV1.getMerkleAgreementHash(
      issuer,
      uri,
      root
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(raftHolderPrivateKey, hash);
    signature = abi.encodePacked(r, s, v);
  }

  function testGiveToManyHappyPath() public {
    address active = raftHolderAddress;
    address recipient1 = claimantAddress;
    uint256 recipient1PrivateKey = claimantPrivateKey;
    address recipient2 = passiveAddress;
    uint256 recipient2PrivateKey = passivePrivateKey;
    address recipient3 = vm.addr(randomPrivateKey);
    uint256 recipient3PrivateKey = randomPrivateKey;

    createRaftAndRegisterSpec();

    bytes memory recipient1Signature = getSignature(
      active,
      recipient1PrivateKey
    );

    bytes memory recipient2Signature = getSignature(
      active,
      recipient2PrivateKey
    );

    bytes memory recipient3Signature = getSignature(
      active,
      recipient3PrivateKey
    );

    address[] memory recipientsAddresses = new address[](3);
    recipientsAddresses[0] = recipient1;
    recipientsAddresses[1] = recipient2;
    recipientsAddresses[2] = recipient3;

    bytes[] memory recipientsSignatures = new bytes[](3);
    recipientsSignatures[0] = recipient1Signature;
    recipientsSignatures[1] = recipient2Signature;
    recipientsSignatures[2] = recipient3Signature;

    vm.prank(active);
    badgesWrappedProxyV1.giveToMany(
      recipientsAddresses,
      specUri,
      recipientsSignatures
    );

    assertEq(badgesWrappedProxyV1.balanceOf(recipient1), 1);
    assertEq(badgesWrappedProxyV1.balanceOf(recipient2), 1);
    assertEq(badgesWrappedProxyV1.balanceOf(recipient3), 1);
  }

  function testGiveToManyWithOneBadSignature() public {
    address active = raftHolderAddress;
    address recipient1 = claimantAddress;
    uint256 recipient1PrivateKey = claimantPrivateKey;
    address recipient2 = passiveAddress;
    uint256 recipient2PrivateKey = passivePrivateKey;
    address recipient3 = vm.addr(randomPrivateKey);

    createRaftAndRegisterSpec();

    bytes memory recipient1Signature = getSignature(
      active,
      recipient1PrivateKey
    );

    bytes memory recipient2Signature = getSignature(
      active,
      recipient2PrivateKey
    );

    bytes memory recipient3Signature = bytes("bad signature");

    address[] memory recipientsAddresses = new address[](3);
    recipientsAddresses[0] = recipient1;
    recipientsAddresses[1] = recipient2;
    recipientsAddresses[2] = recipient3;

    bytes[] memory recipientsSignatures = new bytes[](3);
    recipientsSignatures[0] = recipient1Signature;
    recipientsSignatures[1] = recipient2Signature;
    recipientsSignatures[2] = recipient3Signature;

    vm.prank(active);
    // expect it to revert since we passed in a bad signature
    vm.expectRevert(bytes(errInvalidSig));
    badgesWrappedProxyV1.giveToMany(
      recipientsAddresses,
      specUri,
      recipientsSignatures
    );

    // expect the balance of all 3 users to be 0 since it reverted
    assertEq(badgesWrappedProxyV1.balanceOf(recipient1), 0);
    assertEq(badgesWrappedProxyV1.balanceOf(recipient2), 0);
    assertEq(badgesWrappedProxyV1.balanceOf(recipient3), 0);
  }

  function testGiveToManyWithUnauthorizedClaimant() public {
    address active = raftHolderAddress;
    address recipient1 = claimantAddress;
    uint256 recipient1PrivateKey = claimantPrivateKey;
    uint256 recipient2PrivateKey = passivePrivateKey;

    createRaftAndRegisterSpec();

    bytes memory recipient1Signature = getSignature(
      active,
      recipient1PrivateKey
    );

    bytes memory recipient2Signature = getSignature(
      active,
      recipient2PrivateKey
    );

    address[] memory recipientsAddresses = new address[](2);
    recipientsAddresses[0] = recipient1;
    // impersonate a bad actor adding in an address that is not authorized to claim
    recipientsAddresses[1] = vm.addr(randomPrivateKey);

    bytes[] memory recipientsSignatures = new bytes[](2);
    recipientsSignatures[0] = recipient1Signature;
    recipientsSignatures[1] = recipient2Signature;

    vm.prank(active);

    vm.expectRevert(bytes(errInvalidSig));
    badgesWrappedProxyV1.giveToMany(
      recipientsAddresses,
      specUri,
      recipientsSignatures
    );
  }

  function testGiveToManyWithArrayMismatch() public {
    address active = raftHolderAddress;
    address recipient1 = claimantAddress;
    uint256 recipient1PrivateKey = claimantPrivateKey;
    address recipient2 = passiveAddress;

    createRaftAndRegisterSpec();

    bytes memory recipient1Signature = getSignature(
      active,
      recipient1PrivateKey
    );

    address[] memory recipientsAddresses = new address[](2);
    recipientsAddresses[0] = recipient1;
    recipientsAddresses[1] = recipient2;

    bytes[] memory recipientsSignatures = new bytes[](1);
    recipientsSignatures[0] = recipient1Signature;

    vm.prank(active);

    vm.expectRevert(bytes(errGiveToManyArrayMismatch));
    badgesWrappedProxyV1.giveToMany(
      recipientsAddresses,
      specUri,
      recipientsSignatures
    );
  }

  function testClaimFailsWhenClaimingWithAnotherVoucher() public {
    address active = claimantAddress;
    address passive = raftHolderAddress;
    address newOwner = vm.addr(123);
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

    vm.prank(passive);

    // raft holder should approve  the raft to be transferred
    raftWrappedProxyV1.approve(newOwner, raftTokenId);
    vm.prank(passive);
    // raft holder should transfer the raft to the new owner
    raftWrappedProxyV1.transferFrom(passive, newOwner, raftTokenId);
    // new owner should create a signature for the same specUri
    bytes memory newOwnerSignature = getSignature(active, 123);
    // claimant should try to claim the same specUri with the new signature and expect to fail because the token exists
    vm.expectRevert(bytes(errInvalidSig));
    vm.prank(active);
    badgesWrappedProxyV1.take(passive, specUri, newOwnerSignature);
  }

  function testSetSpecToRaftAsUnauthorizedAccount() public {
    address attackerAddress = vm.addr(randomPrivateKey);
    (uint256 raftTokenId, ) = testTake();

    vm.prank(attackerAddress);
    vm.expectRevert(bytes(errOnlyBadgesContract));
    specDataHolderWrappedProxyV1.setSpecToRaft(specUri, raftTokenId);
  }

  function testAirdropHappyPath() public {
    address active = raftHolderAddress;
    address recipient1 = claimantAddress;
    address recipient2 = passiveAddress;
    address recipient3 = vm.addr(randomPrivateKey);

    createRaftAndRegisterSpec();

    address[] memory recipientsAddresses = new address[](3);
    recipientsAddresses[0] = recipient1;
    recipientsAddresses[1] = recipient2;
    recipientsAddresses[2] = recipient3;

    vm.prank(active);
    badgesWrappedProxyV1.airdrop(recipientsAddresses, specUri);

    assertEq(badgesWrappedProxyV1.balanceOf(recipient1), 1);
    assertEq(badgesWrappedProxyV1.balanceOf(recipient2), 1);
    assertEq(badgesWrappedProxyV1.balanceOf(recipient3), 1);
  }
}
