// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.15;
import "@openzeppelin/contracts/access/Ownable.sol";
import { Raft } from "./Raft.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

// import "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

contract SpecDataHolder is Initializable, UUPSUpgradeable, OwnableUpgradeable {
  mapping(string => uint256) private _specToRaft;
  mapping(uint256 => uint256) private _badgeToRaft;

  Raft private raft;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  // The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
  // Not implementing this function because it is used to check who is authorized
  // to update the contract, we're using onlyOwnerfor this purpose.
  function _authorizeUpgrade(address) internal override onlyOwner {}

  // Passing in the owner's address allows an EOA to deploy and set a multi-sig as the owner.
  function initialize(address _raftAddress, address nextOwner) public initializer {
    __Ownable_init();
    setRaft(_raftAddress);
    transferOwnership(nextOwner);
    __UUPSUpgradeable_init();
  }

  function setRaft(address _raftAddress) public onlyOwner {
    raft = Raft(_raftAddress);
  }

  function getRaftAddress() public view returns (address) {
    return address(raft);
  }

  function getRaftTokenId(string memory _specUri) public view returns (uint256) {
    return _specToRaft[_specUri];
  }

  function setBadgeToRaft(uint256 _badgeTokenId, uint256 _raftTokenId) public {
    _badgeToRaft[_badgeTokenId] = _raftTokenId;
  }

  function specIsRegistered(string memory _specUri) public view returns (bool) {
    return _specToRaft[_specUri] != 0;
  }

  function setSpecToRaft(string memory _specUri, uint256 _raftTokenId) public {
    _specToRaft[_specUri] = _raftTokenId;
  }

  function getRaftOwner(uint256 raftTokenId) public view returns (address) {
    return raft.ownerOf(raftTokenId);
  }
}
