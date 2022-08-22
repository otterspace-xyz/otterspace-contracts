// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;
// import "../node_modules/hardhat/console.sol";

import "./SpecDataHolder.sol";
import { IERC4973 } from "ERC4973/interfaces/IERC4973.sol";
import { SignatureCheckerUpgradeable } from "@openzeppelin-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import { IERC721Metadata } from "./interfaces/IERC721Metadata.sol";

bytes32 constant AGREEMENT_HASH = keccak256("Agreement(address active,address passive,string tokenURI)");

contract Badges is
  IERC721Metadata,
  IERC4973,
  ERC165Upgradeable,
  UUPSUpgradeable,
  OwnableUpgradeable,
  EIP712Upgradeable
{
  using BitMaps for BitMaps.BitMap;
  BitMaps.BitMap private _usedHashes;
  string private _name;
  string private _symbol;

  mapping(uint256 => address) private _owners;
  mapping(uint256 => string) private _tokenURIs;
  mapping(address => uint256) private _balances;

  event SpecCreated(address indexed to, string specUri, uint256 indexed raftTokenId, address indexed raftAddress);

  SpecDataHolder private specDataHolder;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    string memory name_,
    string memory symbol_,
    string memory version_,
    address nextOwner,
    address specDataHolderAddress
  ) public initializer {
    _name = name_;
    _symbol = symbol_;
    __ERC165_init();
    __Ownable_init();
    __EIP712_init(name_, version_);
    __UUPSUpgradeable_init();
    transferOwnership(nextOwner);
    specDataHolder = SpecDataHolder(specDataHolderAddress);
  }

  // The owner can call this once only. They should call this when the contract is first deployed.
  function setDataHolder(address _dataHolder) external virtual onlyOwner {
    // require(address(dataHolder) == address(0x0));
    specDataHolder = SpecDataHolder(_dataHolder);
  }

  function give(
    address to,
    string calldata uri,
    bytes calldata signature
  ) external virtual override returns (uint256) {
    require(msg.sender != to, "give: cannot give from self");
    uint256 tokenId = _safeCheckAgreement(msg.sender, to, uri, signature);
    _mint(to, tokenId, uri);
    _usedHashes.set(tokenId);
    return tokenId;
  }

  function take(
    address from,
    string calldata uri,
    bytes calldata signature
  ) external virtual override returns (uint256) {
    require(msg.sender != from, "take: cannot take from self");
    uint256 tokenId = _safeCheckAgreement(msg.sender, from, uri, signature);
    _mint(msg.sender, tokenId, uri);
    _usedHashes.set(tokenId);
    return tokenId;
  }

  function getDataHolderAddress() external view returns (address) {
    return address(specDataHolder);
  }

  function createSpec(string memory specUri, uint256 raftTokenId) external virtual {
    address raftOwner = specDataHolder.getRaftOwner(raftTokenId);
    require(raftOwner == msg.sender, "createSpec: unauthorized");
    require(!specDataHolder.specIsRegistered(specUri), "createSpec: spec already registered");

    specDataHolder.setSpecToRaft(specUri, raftTokenId);

    emit SpecCreated(msg.sender, specUri, raftTokenId, specDataHolder.getRaftAddress());
  }

  function getHash(
    address from,
    address to,
    string calldata tokenURI_
  ) external view virtual returns (bytes32) {
    return _getHash(from, to, tokenURI_);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC4973).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function name() external view virtual override returns (string memory) {
    return _name;
  }

  function symbol() external view virtual override returns (string memory) {
    return _symbol;
  }

  function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
    require(_exists(tokenId), "tokenURI: token doesn't exist");
    return _tokenURIs[tokenId];
  }

  function unequip(uint256 tokenId) external virtual override {
    require(msg.sender == ownerOf(tokenId), "unequip: sender must be owner");
    _usedHashes.unset(tokenId);
    _burn(tokenId);
  }

  function balanceOf(address owner_) external view virtual override returns (uint256) {
    require(owner_ != address(0), "balanceOf: address zero is not a valid owner_");
    return _balances[owner_];
  }

  function ownerOf(uint256 tokenId_) public view virtual override returns (address) {
    address owner_ = _owners[tokenId_];
    require(owner_ != address(0), "ownerOf: token doesn't exist");
    return owner_;
  }

  function _mint(
    address to,
    uint256 tokenId,
    string memory uri
  ) internal virtual returns (uint256) {
    uint256 raftTokenId = specDataHolder.getRaftTokenId(uri);

    // only registered specs can be used for minting
    require(raftTokenId != 0, "_mint: spec is not registered");

    require(!_exists(tokenId), "mint: tokenID exists");
    _balances[to] += 1;
    _owners[tokenId] = to;
    _tokenURIs[tokenId] = uri;
    emit Transfer(address(0), to, tokenId);

    specDataHolder.setBadgeToRaft(tokenId, raftTokenId);
    return tokenId;
  }

  function _safeCheckAgreement(
    address active,
    address passive,
    string calldata uri,
    bytes calldata signature
  ) internal virtual returns (uint256) {
    bytes32 hash = _getHash(active, passive, uri);
    uint256 tokenId = uint256(hash);

    require(
      SignatureCheckerUpgradeable.isValidSignatureNow(passive, hash, signature),
      "_safeCheckAgreement: invalid signature"
    );
    require(!_usedHashes.get(tokenId), "_safeCheckAgreement: already used");
    return tokenId;
  }

  function _getHash(
    address active,
    address passive,
    string calldata uri
  ) internal view virtual returns (bytes32) {
    bytes32 structHash = keccak256(abi.encode(AGREEMENT_HASH, active, passive, keccak256(bytes(uri))));
    return _hashTypedDataV4(structHash);
  }

  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return _owners[tokenId] != address(0);
  }

  function _burn(uint256 tokenId) internal virtual {
    address owner_ = ownerOf(tokenId);

    _balances[owner_] -= 1;
    delete _owners[tokenId];
    delete _tokenURIs[tokenId];

    emit Transfer(owner_, address(0), tokenId);
  }

  // Not implementing this function because it is used to check who is authorized
  // to update the contract, we're using onlyOwner for this purpose.
  function _authorizeUpgrade(address) internal override onlyOwner {}
}
