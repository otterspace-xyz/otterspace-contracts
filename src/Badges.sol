// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import { IERC4973 } from "ERC4973/interfaces/IERC4973.sol";
import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import { OwnableUpgradeable } from "@openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import { EIP712Upgradeable } from "@openzeppelin-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ERC165Upgradeable } from "@openzeppelin-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import { IERC721Metadata } from "./interfaces/IERC721Metadata.sol";

import { BadgeStorage } from "./BadgeStorage.sol";
import { Utils } from "./Utils.sol";
import { Mint } from "./Mint.sol";

contract Badges is
  IERC721Metadata,
  IERC4973,
  ERC165Upgradeable,
  UUPSUpgradeable,
  OwnableUpgradeable,
  EIP712Upgradeable,
  BadgeStorage,
  Utils,
  Mint
{
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice Initialize the contract
   * @dev only called once when the proxy is deployed. Allows the contract to be upgraded
   * @param _nextOwner address of the owner
   */
  function initialize(
    string memory _name,
    string memory _symbol,
    string memory _version,
    address _nextOwner,
    address _specDataHolderAddress
  ) public override initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();
    transferOwnership(_nextOwner);
  }

  /**
   * @notice Allows the owner of a badge spec to mint a badge to someone who has requested it
   * @dev Take is called by somebody who has already been added to an allow list.
   * @param _to the person who is receiving the badge
   * @param _uri the uri of the badge spec
   * @param _signature the signature used to verify that the person receiving the badge actually requested it
   */
  function give(
    address _to,
    string calldata _uri,
    bytes calldata _signature
  ) external virtual override returns (uint256) {
    require(msg.sender != _to, "give: cannot give from self");
    uint256 voucherHashId = safeCheckAgreement(msg.sender, _to, _uri, _signature);
    uint256 tokenId = mint(_to, _uri);
    setUsedHashId(voucherHashId);
    voucherHashIds[tokenId] = voucherHashId;
    return tokenId;
  }

  /**
   * @notice Allows a user to mint a badge from a voucher
   * @dev Take is called by somebody who has already been added to an allow list.
   * @param _from the person who issued the voucher, who is permitting them to mint the badge.
   * @param _uri the uri of the badge spec
   * @param _signature the signature used to verify that the person minting has permission from the issuer
   */
  function take(
    address _from,
    string calldata _uri,
    bytes calldata _signature
  ) external virtual override returns (uint256) {
    require(msg.sender != _from, "take: cannot take from self");

    uint256 voucherHashId = safeCheckAgreement(msg.sender, _from, _uri, _signature);
    uint256 tokenId = mint(msg.sender, _uri);
    setUsedHashId(voucherHashId);
    voucherHashIds[tokenId] = voucherHashId;
    return tokenId;
  }

  /**
   * @notice Allows a Raft token holder to create a badge spec
   * @dev Data is stored in the SpecDataHolder contract
   * @param _specUri the uri of the badge spec
   * @param _raftTokenId the id of the raft token
   */
  function createSpec(string memory _specUri, uint256 _raftTokenId)
    external
    virtual
    senderIsRaftOwner(_raftTokenId, "createSpec")
  {
    require(!specDataHolder.isSpecRegistered(_specUri), "createSpec: spec already registered");

    specDataHolder.setSpecToRaft(_specUri, _raftTokenId);

    emit SpecCreated(msg.sender, _specUri, _raftTokenId, specDataHolder.getRaftAddress());
  }

  function name() external view virtual override returns (string memory) {
    return name_;
  }

  function symbol() external view virtual override returns (string memory) {
    return symbol_;
  }

  function tokenURI(uint256 _tokenId) external view virtual returns (string memory) {
    require(exists(_tokenId), "tokenURI: token doesn't exist");
    return tokenURIs[_tokenId];
  }

  /**
   * @notice Allows a user to disassociate themselves from a badge
   * @param _tokenId the id of the badge
   */
  function unequip(uint256 _tokenId) external virtual override tokenExists(_tokenId) {
    require(msg.sender == owners[_tokenId], "unequip: sender must be owner");

    uint256 voucherHashId = voucherHashIds[_tokenId];
    unsetUsedHashId(voucherHashId);
    burn(_tokenId);
  }

  function balanceOf(address _owner) external view virtual override returns (uint256) {
    require(_owner != address(0), "balanceOf: address zero is not a valid owner_");
    return balances[_owner];
  }

  function ownerOf(uint256 _tokenId) external view virtual override tokenExists(_tokenId) returns (address) {
    return owners[_tokenId];
  }

  /**
   * @notice Revokes a badge from a user
   * @dev we're storing the reason as a uint because the string values may change over time
   * Reason 0: Abuse
   * Reason 1: Left community
   * Reason 2: Tenure ended
   * Reason 3: Other
   * @param _raftTokenId The raft token id
   * @param _badgeId tokenId of the badge to be revoked
   * @param _reason an integer representing the reason for revoking the badge
   */
  function revokeBadge(
    uint256 _raftTokenId,
    uint256 _badgeId,
    uint8 _reason
  ) external tokenExists(_badgeId) senderIsRaftOwner(_raftTokenId, "revokeBadge") {
    require(!getRevokedBadgeHash(_badgeId), "revokeBadge: badge already revoked");
    setRevokedBadgeHash(_badgeId);
    emit BadgeRevoked(_badgeId, msg.sender, _reason);
  }

  /**
   * @notice Reinstates a badge for a user
   * @dev we're using bitmaps instead of a mapping to save gas
   * @param _raftTokenId The raft token id
   * @param _badgeId tokenId of the badge to be revoked
   */
  function reinstateBadge(uint256 _raftTokenId, uint256 _badgeId)
    external
    tokenExists(_badgeId)
    senderIsRaftOwner(_raftTokenId, "reinstateBadge")
  {
    require(getRevokedBadgeHash(_badgeId), "reinstateBadge: badge not revoked");
    unsetRevokedBadgeHash(_badgeId);
    emit BadgeReinstated(_badgeId, msg.sender);
  }

  function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
    return
      _interfaceId == type(IERC721Metadata).interfaceId ||
      _interfaceId == type(IERC4973).interfaceId ||
      super.supportsInterface(_interfaceId);
  }

  function burn(uint256 _tokenId) internal virtual {
    address _owner = owners[_tokenId];

    balances[_owner] -= 1;
    delete owners[_tokenId];
    delete tokenURIs[_tokenId];
    delete voucherHashIds[_tokenId];
    emit Transfer(_owner, address(0), _tokenId);
  }
}
