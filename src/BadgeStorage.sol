// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import { IERC4973 } from "ERC4973/interfaces/IERC4973.sol";
import { SignatureCheckerUpgradeable } from "@openzeppelin-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import { OwnableUpgradeable } from "@openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import { EIP712Upgradeable } from "@openzeppelin-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ERC165Upgradeable } from "@openzeppelin-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import { IERC721Metadata } from "./interfaces/IERC721Metadata.sol";
import { ISpecDataHolder } from "./interfaces/ISpecDataHolder.sol";

contract BadgeStorage is ERC165Upgradeable, UUPSUpgradeable, OwnableUpgradeable, EIP712Upgradeable {
  using BitMaps for BitMaps.BitMap;
  BitMaps.BitMap internal usedHashes;
  string internal name_;
  string internal symbol_;

  mapping(uint256 => address) internal owners;
  mapping(uint256 => string) internal tokenURIs;
  mapping(address => uint256) internal balances;

  ISpecDataHolder internal specDataHolder;

  mapping(uint256 => uint256) internal voucherHashIds;
  BitMaps.BitMap internal revokedBadgesHashes;
  event SpecCreated(address indexed to, string specUri, uint256 indexed raftTokenId, address indexed raftAddress);
  event BadgeRevoked(uint256 indexed tokenId, address indexed from, uint8 indexed reason);
  event BadgeReinstated(uint256 indexed tokenId, address indexed from);

  function initialize(
    string memory _name,
    string memory _symbol,
    string memory _version,
    address _nextOwner,
    address _specDataHolderAddress
  ) public virtual initializer {
    name_ = _name;
    symbol_ = _symbol;
    specDataHolder = ISpecDataHolder(_specDataHolderAddress);

    __ERC165_init();
    __Ownable_init();
    __EIP712_init(_name, _version);
    __UUPSUpgradeable_init();
    transferOwnership(_nextOwner);
  }

  function setUsedHashId(uint256 _voucherHashId) internal virtual {
    usedHashes.set(_voucherHashId);
  }

  function getUsedHashId(uint256 _voucherHashId) internal virtual returns (bool) {
    return usedHashes.get(_voucherHashId);
  }

  function unsetUsedHashId(uint256 _voucherHashId) internal virtual {
    usedHashes.unset(_voucherHashId);
  }

  function getRevokedBadgeHash(uint256 _badgeId) internal view virtual returns (bool) {
    return revokedBadgesHashes.get(_badgeId);
  }

  function setRevokedBadgeHash(uint256 _badgeId) internal virtual {
    revokedBadgesHashes.set(_badgeId);
  }

  function unsetRevokedBadgeHash(uint256 _badgeId) internal virtual {
    revokedBadgesHashes.unset(_badgeId);
  }

  function _authorizeUpgrade(address) internal virtual override onlyOwner {}
}
