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
  constructor(
    address _implementation,
    bytes memory _data
  ) ERC1967Proxy(_implementation, _data) {}
}

contract BadgesTest is Test {
  Badges badgesImplementationV1;
  SpecDataHolder specDataHolderImplementationV1;
  Raft raftImplementationV1;

  UUPSProxy badgesUUPS;
  UUPSProxy raftUUPS;
  UUPSProxy sdhUUPS;

  Badges badgesProxy;
  Raft raftProxy;
  SpecDataHolder sdhProxy;

  uint256 passivePrivateKey =
    0xad54bdeade5537fb0a553190159783e45d02d316a992db05cbed606d3ca36b39;

  uint256 raftHolderPrivateKey =
    0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
  address passiveAddress = vm.addr(passivePrivateKey);

  uint256 claimantPrivateKey =
    0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;

  uint256 randomPrivateKey =
    0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

  address randomAddress = vm.addr(randomPrivateKey);

  address raftOwner = vm.addr(raftHolderPrivateKey);

  address claimantAddress = vm.addr(claimantPrivateKey);
  address zeroAddress = address(0);

  string[] specUris = ["spec1", "spec2"];
  string badTokenUri = "bad token uri";

  string errAirdropUnauthorized = "airdrop: unauthorized";
  string err721InvalidTokenId = "ERC721: invalid token ID";
  string errBadgeAlreadyRevoked = "revokeBadge: badge already revoked";
  string errBalanceOfNotValidOwner =
    "balanceOf: address(0) is not a valid owner";
  string errGiveToManyArrayMismatch =
    "giveToMany: recipients and signatures length mismatch";
  string errGiveRequestedBadgeToManyArrayMismatch =
    "giveRequestedBadgeToMany: recipients and signatures length mismatch";
  string errInvalidSig = "safeCheckAgreement: invalid signature";
  string errGiveRequestedBadgeInvalidSig =
    "giveRequestedBadge: invalid signature";
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
  uint256 raftTokenId;

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

    badgesUUPS = new UUPSProxy(address(badgesImplementationV1), "");
    raftUUPS = new UUPSProxy(address(raftImplementationV1), "");
    sdhUUPS = new UUPSProxy(address(specDataHolderImplementationV1), "");

    badgesProxy = Badges(address(badgesUUPS));
    raftProxy = Raft(address(raftUUPS));
    sdhProxy = SpecDataHolder(address(sdhUUPS));

    badgesProxy.initialize(
      "Badges",
      "BADGES",
      "0.1.0",
      contractOwner,
      address(sdhUUPS)
    );
    raftProxy.initialize(contractOwner, "Raft", "RAFT");
    sdhProxy.initialize(address(raftUUPS), contractOwner);

    sdhProxy.setBadgesAddress(address(badgesUUPS));

    vm.label(passiveAddress, "passive");
    vm.expectEmit(true, true, true, false);
    emit Transfer(zeroAddress, raftOwner, 1);
    raftTokenId = raftProxy.mint(raftOwner, specUri);

    assertEq(raftTokenId, 1);
    assertEq(raftProxy.balanceOf(raftOwner), 1);

    vm.prank(raftOwner);
    badgesProxy.createSpec(specUri, raftTokenId);
    assertEq(sdhProxy.isSpecRegistered(specUri), true);
  }

  function getSignature(
    bytes32 hash,
    uint256 privateKey
  ) internal returns (bytes memory) {
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);
    return signature;
  }

  function testIERC721Metadata() public {
    assertTrue(
      badgesProxy.supportsInterface(type(IERC721Metadata).interfaceId)
    );
  }

  function testIERC4973() public {
    bytes4 interfaceId = type(IERC4973).interfaceId;
    assertEq(interfaceId, bytes4(0x8d7bac72));
    assertTrue(badgesProxy.supportsInterface(interfaceId));
  }

  function testCheckMetadata() public {
    assertEq(badgesProxy.name(), "Badges");
    assertEq(badgesProxy.symbol(), "BADGES");
  }

  function testIfEmptyAddressReturnsBalanceZero(address fuzzAddress) public {
    vm.assume(fuzzAddress != zeroAddress);
    assertEq(badgesProxy.balanceOf(address(fuzzAddress)), 0);
  }

  function testThrowOnZeroAddress() public {
    vm.expectRevert(bytes(errBalanceOfNotValidOwner));
    badgesProxy.balanceOf(zeroAddress);
  }

  function testFailGetOwnerOfNonExistentTokenId(uint256 tokenId) public view {
    // needs assert
    badgesProxy.ownerOf(tokenId);
  }

  // DATA HOLDER TESTS

  function testSetDataHolder(address fuzzAddress) public {
    address dataHolderAddress = address(sdhUUPS);
    assertEq(badgesProxy.getDataHolderAddress(), dataHolderAddress);

    badgesProxy.setDataHolder(fuzzAddress);
    assertEq(badgesProxy.getDataHolderAddress(), fuzzAddress);
  }

  function testSetDataHolderAsNonOwner() public {
    address dataHolderAddress = address(sdhUUPS);
    assertEq(badgesProxy.getDataHolderAddress(), dataHolderAddress);

    vm.prank(randomAddress);
    vm.expectRevert(bytes(errNotOwner));
    badgesProxy.setDataHolder(randomAddress);
  }

  function testGetOwnerOfContract() public {
    assertEq(badgesProxy.owner(), address(this));
  }

  function testTransferOwnership(address fuzzAddress) public {
    vm.assume(fuzzAddress != zeroAddress);
    address currentOwner = badgesProxy.owner();

    assertEq(currentOwner, address(this));
    badgesProxy.transferOwnership(fuzzAddress);

    assertEq(badgesProxy.owner(), fuzzAddress);
  }

  function testTransferOwnershipFromNonOwner() public {
    address currentOwner = badgesProxy.owner();
    assertEq(currentOwner, address(this));

    vm.prank(randomAddress);
    vm.expectRevert(bytes(errNotOwner));
    badgesProxy.transferOwnership(randomAddress);
  }

  function testCreateSpecAsRaftOwner() public {
    vm.prank(raftOwner);
    badgesProxy.createSpec(specUris[1], raftTokenId);
    assertEq(sdhProxy.isSpecRegistered(specUris[1]), true);
  }

  function testCreateSpecAsAdmin() public {
    address admin = address(123);
    address[] memory admins = new address[](1);
    admins[0] = admin;
    bool[] memory isAdmin = new bool[](1);
    isAdmin[0] = true;

    vm.prank(raftOwner);
    raftProxy.setAdmins(raftTokenId, admins, isAdmin);
    assertEq(raftProxy.isAdminActive(raftTokenId, admins[0]), true);

    vm.prank(admin);
    badgesProxy.createSpec(specUris[1], raftTokenId);
    assertEq(sdhProxy.isSpecRegistered(specUris[1]), true);
  }

  function testCreateSpecAsDeactivatedAdmin() public {
    address admin = address(123);

    address[] memory admins = new address[](1);
    admins[0] = admin;
    bool[] memory isAdmin = new bool[](1);
    isAdmin[0] = false;

    vm.prank(raftOwner);
    raftProxy.setAdmins(raftTokenId, admins, isAdmin);
    assertEq(raftProxy.isAdminActive(raftTokenId, admins[0]), false);

    vm.prank(admin);
    vm.expectRevert(bytes(errCreateSpecUnauthorized));
    badgesProxy.createSpec(specUri, raftTokenId);
  }

  function testCreateSpecAsUnauthorizedAccount() public {
    vm.prank(randomAddress);
    vm.expectRevert(bytes(errCreateSpecUnauthorized));
    badgesProxy.createSpec(specUri, raftTokenId);
  }

  function testCreatingWithExistingSpecUriShouldRevert() public {
    assertEq(sdhProxy.isSpecRegistered(specUri), true);

    vm.expectRevert(bytes(errSpecAlreadyRegistered));
    vm.prank(raftOwner);
    badgesProxy.createSpec(specUri, raftTokenId);
  }

  // TODO: write test for a non-owner calling transferOwnership
  // tricky because we need to call a proxy to do this

  // TAKE TESTS
  // happy path
  function testTake() public returns (uint256, uint256) {
    address active = claimantAddress;
    address passive = raftOwner;
    bytes32 hash = badgesProxy.getAgreementHash(active, passive, specUri);
    bytes memory signature = getSignature(hash, raftHolderPrivateKey);
    vm.prank(active);
    uint256 tokenId = badgesProxy.take(passive, specUri, signature);

    assertEq(badgesProxy.balanceOf(active), 1);
    assertEq(badgesProxy.tokenURI(tokenId), specUri);
    assertEq(badgesProxy.ownerOf(tokenId), active);

    return (raftTokenId, tokenId);
  }

  function testTakeAfterIssuerTransferredRaftShouldFail()
    public
    returns (uint256, uint256)
  {
    address active = claimantAddress;
    address passive = raftOwner;
    bytes32 hash = badgesProxy.getAgreementHash(active, passive, specUri);
    bytes memory signature = getSignature(hash, raftHolderPrivateKey);
    address newRaftHolder = address(123);

    // transfer raft to new holder
    vm.prank(raftOwner);
    raftProxy.transferFrom(raftOwner, newRaftHolder, raftTokenId);

    vm.prank(claimantAddress);
    vm.expectRevert(bytes(errTakeUnauthorized));
    uint256 tokenId = badgesProxy.take(raftOwner, specUri, signature);

    assertEq(badgesProxy.balanceOf(claimantAddress), 0);

    return (raftTokenId, tokenId);
  }

  function testTakeAfterIssuerTransferredRaftAndSetPreviousHolderAsAdmin()
    public
    returns (uint256, uint256)
  {
    address active = claimantAddress;
    address passive = raftOwner;
    bytes32 hash = badgesProxy.getAgreementHash(active, passive, specUri);
    bytes memory signature = getSignature(hash, raftHolderPrivateKey);
    address newRaftHolder = address(123);

    // transfer raft to new holder
    vm.prank(raftOwner);
    raftProxy.transferFrom(raftOwner, newRaftHolder, raftTokenId);

    address[] memory admins = new address[](1);
    admins[0] = raftOwner;
    bool[] memory isAdmin = new bool[](1);
    isAdmin[0] = true;

    vm.prank(newRaftHolder);
    raftProxy.setAdmins(raftTokenId, admins, isAdmin);

    vm.prank(claimantAddress);
    uint256 tokenId = badgesProxy.take(raftOwner, specUri, signature);

    assertEq(badgesProxy.balanceOf(claimantAddress), 1);
    assertEq(badgesProxy.tokenURI(tokenId), specUri);
    assertEq(badgesProxy.ownerOf(tokenId), claimantAddress);

    return (raftTokenId, tokenId);
  }

  function testTakeWithSigFromUnauthorizedActor() public {
    address active = claimantAddress;
    address passive = raftOwner;
    uint256 badActorPrivateKey = 123;

    bytes32 hash = badgesProxy.getAgreementHash(active, passive, specUri);
    bytes memory signature = getSignature(hash, badActorPrivateKey);

    vm.prank(active);
    vm.expectRevert(bytes(errInvalidSig));
    uint256 tokenId = badgesProxy.take(passive, specUri, signature);

    assertEq(tokenId, 0);
    assertEq(badgesProxy.balanceOf(active), 0);
  }

  function testTakeWithUnregisteredSpec() public {
    address active = claimantAddress;
    address passive = raftOwner;
    bytes32 hash = badgesProxy.getAgreementHash(active, passive, specUri);
    bytes memory signature = getSignature(hash, raftHolderPrivateKey);

    vm.expectRevert(bytes(errInvalidSig));
    vm.prank(claimantAddress);
    // try to take on a specUri that you don't have a sig for
    badgesProxy.take(raftOwner, specUris[1], signature);
  }

  function testTakeWithBadTokenUri() public {
    address active = claimantAddress;

    bytes32 hash = badgesProxy.getAgreementHash(
      active,
      vm.addr(raftHolderPrivateKey),
      badTokenUri
    );
    // passive is always the one signing away permission for the active party to do something
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(raftHolderPrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    // errors with this because we check for a valid spec URI before validating the signature
    vm.expectRevert(bytes(errInvalidSig));
    badgesProxy.take(passiveAddress, specUri, signature);
  }

  function testMintWithConsent() public {
    address issuer = raftOwner;
    address recipient = claimantAddress;
    testCreateSpecAsRaftOwner();

    bytes32 agreementHash = badgesProxy.getAgreementHash(
      recipient,
      issuer,
      specUri
    );
    bytes32 requestHash = badgesProxy.getRequestHash(recipient, specUri);

    bytes memory issuerSignature = getSignature(
      agreementHash,
      raftHolderPrivateKey
    );
    bytes memory recipientSignature = getSignature(
      requestHash,
      claimantPrivateKey
    );

    vm.prank(raftOwner);
    badgesProxy.mintWithConsent(
      issuer,
      recipient,
      specUri,
      issuerSignature,
      recipientSignature
    );

    assertEq(badgesProxy.balanceOf(recipient), 1);
  }

  function testMintWithConsentInvalidIssuerSignature() public {
    address issuer = raftOwner;
    address recipient = claimantAddress;
    testCreateSpecAsRaftOwner();

    bytes32 agreementHash = badgesProxy.getAgreementHash(
      issuer,
      recipient,
      specUri
    );
    bytes32 requestHash = badgesProxy.getRequestHash(recipient, specUri);

    // Setup invalid issuer signature
    bytes memory issuerSignature = getSignature(
      agreementHash,
      claimantPrivateKey
    );

    bytes memory recipientSignature = getSignature(
      requestHash,
      claimantPrivateKey
    );

    vm.prank(raftOwner);
    vm.expectRevert("mintWithConsent: invalid issuer signature");
    badgesProxy.mintWithConsent(
      issuer,
      recipient,
      specUri,
      issuerSignature,
      recipientSignature
    );

    assertEq(badgesProxy.balanceOf(recipient), 0);
  }

  function testMintWithConsentInvalidRecipientSignature() public {
    address issuer = raftOwner;
    address recipient = claimantAddress;
    testCreateSpecAsRaftOwner();

    bytes32 agreementHash = badgesProxy.getAgreementHash(
      recipient,
      issuer,
      specUri
    );
    bytes32 requestHash = badgesProxy.getRequestHash(recipient, specUri);

    bytes memory issuerSignature = getSignature(
      agreementHash,
      raftHolderPrivateKey
    );

    // Invalid recipient signature
    bytes memory recipientSignature = getSignature(
      requestHash,
      raftHolderPrivateKey
    );

    vm.prank(raftOwner);
    vm.expectRevert("mintWithConsent: invalid recipient signature");
    badgesProxy.mintWithConsent(
      issuer,
      recipient,
      specUri,
      issuerSignature,
      recipientSignature
    );

    assertEq(badgesProxy.balanceOf(recipient), 0);
  }
}
