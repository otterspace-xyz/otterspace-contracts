// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import { ISpecDataHolder } from "./interfaces/ISpecDataHolder.sol";
import { IERC4973 } from "./interfaces/IERC4973.sol";
import { SignatureCheckerUpgradeable } from "@openzeppelin-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import { OwnableUpgradeable } from "@openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import { EIP712Upgradeable } from "@openzeppelin-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ERC165Upgradeable } from "@openzeppelin-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import { IERC165Upgradeable } from "@openzeppelin-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import { IERC721Metadata } from "./interfaces/IERC721Metadata.sol";
import { IERC5192 } from "./interfaces/IERC5192.sol";
import { IERC721Upgradeable } from "@openzeppelin-upgradeable/token/ERC721/IERC721Upgradeable.sol";

bytes32 constant AGREEMENT_HASH = keccak256("Agreement(address active,address passive,string tokenURI)");

contract Badges is
  IERC721Metadata,
  IERC4973,
  ERC165Upgradeable,
  UUPSUpgradeable,
  OwnableUpgradeable,
  EIP712Upgradeable,
  IERC5192,
  IERC721Upgradeable
{
  using BitMaps for BitMaps.BitMap;
  BitMaps.BitMap private usedHashes;
  string private name_;
  string private symbol_;

  mapping(uint256 => address) private owners;
  mapping(uint256 => string) private tokenURIs;
  mapping(address => uint256) private balances;

  ISpecDataHolder private specDataHolder;

  mapping(uint256 => uint256) private voucherHashIds;
  BitMaps.BitMap private revokedBadgesHashes;

  event SpecCreated(address indexed to, string specUri, uint256 indexed raftTokenId, address indexed raftAddress);
  event BadgeRevoked(uint256 indexed tokenId, address indexed from, uint8 indexed reason);
  event BadgeReinstated(uint256 indexed tokenId, address indexed from);
  event RefreshMetadata(string[] specUris, address sender);

  modifier senderIsRaftOwner(uint256 _raftTokenId, string memory calledFrom) {
    string memory message = string(abi.encodePacked(calledFrom, ": unauthorized"));
    require(specDataHolder.getRaftOwner(_raftTokenId) == msg.sender, message);
    _;
  }

  modifier tokenExists(uint256 _badgeId) {
    require(owners[_badgeId] != address(0), "tokenExists: token doesn't exist");
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice Initialize the contract
   * @dev only called once when the proxy is deployed. Allows the contract to be upgraded
   * @param _name name used for EIP-712 domain
   * @param _symbol symbol used for EIP-712 domain
   * @param _version version used for EIP-712 domain
   * @param _nextOwner address of the owner
   * @param _specDataHolderAddress address of the spec data holder contract
   */
  function initialize(
    string memory _name,
    string memory _symbol,
    string memory _version,
    address _nextOwner,
    address _specDataHolderAddress
  ) public initializer {
    name_ = _name;
    symbol_ = _symbol;
    specDataHolder = ISpecDataHolder(_specDataHolderAddress);

    __ERC165_init();
    __Ownable_init();
    __EIP712_init(_name, _version);
    __UUPSUpgradeable_init();
    transferOwnership(_nextOwner);
  }

  function refreshMetadata(string[] memory _specUris) external onlyOwner {
    require(_specUris.length > 0, "refreshMetadata: no spec uris provided");
    emit RefreshMetadata(_specUris, msg.sender);
  }

  /**
   * @notice Allows the Badges contract to communicate with the SpecDataHolder contract
   * @param _dataHolder address of the SpecDataHolder contract
   */
  function setDataHolder(address _dataHolder) external virtual onlyOwner {
    specDataHolder = ISpecDataHolder(_dataHolder);
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
    usedHashes.set(voucherHashId);
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
    usedHashes.set(voucherHashId);
    voucherHashIds[tokenId] = voucherHashId;
    return tokenId;
  }

  function getDataHolderAddress() external view returns (address) {
    return address(specDataHolder);
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

  function tokenURI(uint256 _tokenId) external view virtual override returns (string memory) {
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
    usedHashes.unset(voucherHashId);
    burn(_tokenId);
  }

  function balanceOf(address _owner) external view virtual override(IERC4973, IERC721Upgradeable) returns (uint256) {
    require(_owner != address(0), "balanceOf: address zero is not a valid owner_");
    return balances[_owner];
  }

  function ownerOf(uint256 _tokenId)
    external
    view
    virtual
    override(IERC4973, IERC721Upgradeable)
    tokenExists(_tokenId)
    returns (address)
  {
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
    require(!revokedBadgesHashes.get(_badgeId), "revokeBadge: badge already revoked");
    revokedBadgesHashes.set(_badgeId);
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
    require(revokedBadgesHashes.get(_badgeId), "reinstateBadge: badge not revoked");
    revokedBadgesHashes.unset(_badgeId);
    emit BadgeReinstated(_badgeId, msg.sender);
  }

  function isBadgeValid(uint256 _badgeId) external view tokenExists(_badgeId) returns (bool) {
    bool isNotRevoked = !revokedBadgesHashes.get(_badgeId);
    return isNotRevoked;
  }

  function supportsInterface(bytes4 _interfaceId)
    public
    view
    virtual
    override(ERC165Upgradeable, IERC165Upgradeable)
    returns (bool)
  {
    return
      _interfaceId == type(IERC721Metadata).interfaceId ||
      _interfaceId == type(IERC4973).interfaceId ||
      _interfaceId == type(IERC5192).interfaceId ||
      super.supportsInterface(_interfaceId);
  }

  function getVoucherHash(uint256 _tokenId) public view virtual returns (uint256) {
    return voucherHashIds[_tokenId];
  }

  function getAgreementHash(
    address _from,
    address _to,
    string calldata _uri
  ) public view virtual returns (bytes32) {
    bytes32 structHash = keccak256(abi.encode(AGREEMENT_HASH, _from, _to, keccak256(bytes(_uri))));
    return _hashTypedDataV4(structHash);
  }

  function getBadgeIdHash(address _to, string memory _uri) public view virtual returns (bytes32) {
    return keccak256(abi.encode(_to, _uri));
  }

  function mint(address _to, string memory _uri) internal virtual returns (uint256) {
    uint256 raftTokenId = specDataHolder.getRaftTokenId(_uri);
    bytes32 hash = getBadgeIdHash(_to, _uri);
    uint256 tokenId = uint256(hash);
    // only registered specs can be used for minting
    require(raftTokenId != 0, "mint: spec is not registered");
    require(!exists(tokenId), "mint: tokenID exists");

    balances[_to] += 1;
    owners[tokenId] = _to;
    tokenURIs[tokenId] = _uri;

    emit Transfer(address(0), _to, tokenId);
    emit Locked(tokenId);
    specDataHolder.setBadgeToRaft(tokenId, raftTokenId);
    return tokenId;
  }

  function locked(uint256 _tokenId) public view tokenExists(_tokenId) returns (bool) {
    return true;
  }

  function safeCheckAgreement(
    address _active,
    address _passive,
    string calldata _uri,
    bytes calldata _signature
  ) internal virtual returns (uint256) {
    bytes32 hash = getAgreementHash(_active, _passive, _uri);
    uint256 voucherHashId = uint256(hash);

    require(
      SignatureCheckerUpgradeable.isValidSignatureNow(_passive, hash, _signature),
      "safeCheckAgreement: invalid signature"
    );
    require(!usedHashes.get(voucherHashId), "safeCheckAgreement: already used");
    return voucherHashId;
  }

  function exists(uint256 _tokenId) internal view virtual returns (bool) {
    return owners[_tokenId] != address(0);
  }

  function burn(uint256 _tokenId) internal virtual {
    address _owner = owners[_tokenId];

    balances[_owner] -= 1;
    delete owners[_tokenId];
    delete tokenURIs[_tokenId];
    delete voucherHashIds[_tokenId];
    emit Transfer(_owner, address(0), _tokenId);
    emit Unlocked(_tokenId);
  }

  // Not implementing this function because it is used to check who is authorized
  // to update the contract, we're using onlyOwner for this purpose.
  function _authorizeUpgrade(address) internal override onlyOwner {}

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external override {
    revert();
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external override {
    revert();
  }

  function approve(address to, uint256 tokenId) external override {
    revert();
  }

  function setApprovalForAll(address operator, bool approved) external override {
    revert();
  }

  function getApproved(uint256 tokenId) external view override returns (address) {
    revert();
  }

  function isApprovedForAll(address owner, address operator) external view override returns (bool) {
    revert();
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external override {
    revert();
  }
}
