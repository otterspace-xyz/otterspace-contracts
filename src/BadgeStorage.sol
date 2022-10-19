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

  function _authorizeUpgrade(address) internal virtual override onlyOwner {}
}
