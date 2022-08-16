// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;
import "../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "../../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

contract TestImplementation is UUPSUpgradeable, OwnableUpgradeable {
  constructor() {
    _disableInitializers();
  }

  function initialize(address nextOwner) public initializer {
    transferOwnership(nextOwner);
    __UUPSUpgradeable_init();
  }

  function _authorizeUpgrade(address) internal override onlyOwner {}
}
