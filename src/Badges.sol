// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;
// import "../node_modules/hardhat/console.sol";

import { ISpecDataHolder } from "./interfaces/ISpecDataHolder.sol";
import { IERC4973 } from "./interfaces/IERC4973.sol";
import { SignatureCheckerUpgradeable } from "@openzeppelin-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import { IERC721Metadata } from "./interfaces/IERC721Metadata.sol";
import "@openzeppelin-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

bytes32 constant AGREEMENT_HASH = keccak256("Agreement(address active,address passive,string tokenURI)");

contract Badges is
  IERC721Metadata,
  IERC4973,
  ERC165Upgradeable,
  UUPSUpgradeable,
  OwnableUpgradeable,
  EIP712Upgradeable,
  ERC721EnumerableUpgradeable
{
  using BitMaps for BitMaps.BitMap;
  BitMaps.BitMap private usedHashes;
  string private name_;
  string private symbol_;

  mapping(uint256 => address) private owners;
  mapping(uint256 => string) private tokenURIs;
  mapping(address => uint256) private balances;

  ISpecDataHolder private specDataHolder;
  mapping(uint256 => uint256) raftToBadgeSpecCreationPermissions;

  event SpecCreated(address indexed to, string specUri, uint256 indexed raftTokenId, address indexed raftAddress);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

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
    __ERC721Enumerable_init();
  }

  function supportsInterface(bytes4 _interfaceId)
    public
    view
    virtual
    override(ERC165Upgradeable, ERC721EnumerableUpgradeable)
    returns (bool)
  {
    return
      _interfaceId == type(IERC721Metadata).interfaceId ||
      _interfaceId == type(IERC4973).interfaceId ||
      super.supportsInterface(_interfaceId);
  }

  // permissionInt:
  // 0: only raft owner
  // 1: all badge holders associated with that RAFT
  // 2: only specific badge holders
  function setBadgeSpecCreationPermissions(uint256 raftTokenId, uint256 permissionInt) external {
    // this function will only be called when a DAO is created
    // would it be helpful in any way to emit an event here?
    raftToBadgeSpecCreationPermissions[raftTokenId] = permissionInt;
  }

  // The owner can call this once only. They should call this when the contract is first deployed.
  function setDataHolder(address _dataHolder) external virtual onlyOwner {
    // require(address(dataHolder) == address(0x0));
    specDataHolder = ISpecDataHolder(_dataHolder);
  }

  function give(
    address _to,
    string calldata _uri,
    bytes calldata _signature
  ) external virtual override returns (uint256) {
    require(msg.sender != _to, "give: cannot give from self");
    uint256 tokenId = safeCheckAgreement(msg.sender, _to, _uri, _signature);
    mint(_to, tokenId, _uri);
    usedHashes.set(tokenId);
    return tokenId;
  }

  function take(
    address _from,
    string calldata _uri,
    bytes calldata _signature
  ) external virtual override returns (uint256) {
    require(msg.sender != _from, "take: cannot take from self");

    uint256 tokenId = safeCheckAgreement(msg.sender, _from, _uri, _signature);
    mint(msg.sender, tokenId, _uri);
    usedHashes.set(tokenId);

    return tokenId;
  }

  function getDataHolderAddress() external view returns (address) {
    return address(specDataHolder);
  }

  function createSpecAsRaftHolder(string memory _specUri, uint256 _raftTokenId) external virtual {
    require(specDataHolder.getRaftOwner(_raftTokenId) == msg.sender, "createSpecAsRaftHolder: unauthorized");
    require(!specDataHolder.isSpecRegistered(_specUri), "createSpecAsRaftHolder: spec already registered");
    specDataHolder.setSpecToRaft(_specUri, _raftTokenId);
    emit SpecCreated(msg.sender, _specUri, _raftTokenId, specDataHolder.getRaftAddress());
  }

  function createSpecAsHolderOfAnyBadge(
    string memory _specUri,
    uint256 _raftTokenId,
    uint256 badgeId
  ) external virtual {
    require(owners[badgeId] == msg.sender, "createSpecAsHolderOfAnyBadge: unauthorized");
    specDataHolder.setSpecToRaft(_specUri, _raftTokenId);
    emit SpecCreated(msg.sender, _specUri, _raftTokenId, specDataHolder.getRaftAddress());
  }

  function name() public view virtual override(ERC721Upgradeable, IERC721Metadata) returns (string memory) {
    return name_;
  }

  function symbol() public view virtual override(ERC721Upgradeable, IERC721Metadata) returns (string memory) {
    return symbol_;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override(ERC721Upgradeable, IERC721Metadata)
    returns (string memory)
  {
    require(exists(_tokenId), "tokenURI: token doesn't exist");
    return tokenURIs[_tokenId];
  }

  function unequip(uint256 _tokenId) external virtual override {
    require(owners[_tokenId] != address(0), "unequip: token doesn't exist");
    require(msg.sender == owners[_tokenId], "unequip: sender must be owner");
    usedHashes.unset(_tokenId);
    burn(_tokenId);
  }

  function balanceOf(address _owner)
    public
    view
    virtual
    override(IERC721Upgradeable, ERC721Upgradeable, IERC4973)
    returns (uint256)
  {
    require(_owner != address(0), "balanceOf: address zero is not a valid owner_");
    return balances[_owner];
  }

  function ownerOf(uint256 _tokenId)
    public
    view
    virtual
    override(IERC721Upgradeable, ERC721Upgradeable, IERC4973)
    returns (address)
  {
    address owner_ = owners[_tokenId];
    require(owner_ != address(0), "ownerOf: token doesn't exist");
    return owner_;
  }

  function mint(
    address _to,
    uint256 _tokenId,
    string memory _uri
  ) internal virtual returns (uint256) {
    uint256 raftTokenId = specDataHolder.getRaftTokenId(_uri);

    // only registered specs can be used for minting
    require(raftTokenId != 0, "mint: spec is not registered");
    require(!exists(_tokenId), "mint: tokenID exists");

    balances[_to] += 1;
    owners[_tokenId] = _to;
    tokenURIs[_tokenId] = _uri;

    emit Transfer(address(0), _to, _tokenId);

    specDataHolder.setBadgeToRaft(_tokenId, raftTokenId);
    return _tokenId;
  }

  function safeCheckAgreement(
    address _active,
    address _passive,
    string calldata _uri,
    bytes calldata _signature
  ) internal virtual returns (uint256) {
    bytes32 hash = getHash(_active, _passive, _uri);
    uint256 tokenId = uint256(hash);

    require(
      SignatureCheckerUpgradeable.isValidSignatureNow(_passive, hash, _signature),
      "safeCheckAgreement: invalid signature"
    );
    require(!usedHashes.get(tokenId), "safeCheckAgreement: already used");
    return tokenId;
  }

  function getHash(
    address _from,
    address _to,
    string calldata _uri
  ) public view virtual returns (bytes32) {
    bytes32 structHash = keccak256(abi.encode(AGREEMENT_HASH, _from, _to, keccak256(bytes(_uri))));
    return _hashTypedDataV4(structHash);
  }

  function exists(uint256 _tokenId) internal view virtual returns (bool) {
    return owners[_tokenId] != address(0);
  }

  function burn(uint256 _tokenId) internal virtual {
    address _owner = owners[_tokenId];

    balances[_owner] -= 1;
    delete owners[_tokenId];
    delete tokenURIs[_tokenId];

    emit Transfer(_owner, address(0), _tokenId);
  }

  // Not implementing this function because it is used to check who is authorized
  // to update the contract, we're using onlyOwner for this purpose.
  function _authorizeUpgrade(address) internal override onlyOwner {}
}
