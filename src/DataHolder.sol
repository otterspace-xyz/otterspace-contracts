// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.15;
import "@openzeppelin/contracts/access/Ownable.sol";

contract DataHolder is Ownable {
  address public badgesAddress;
  address public raftAddress;

  mapping(string => uint256) private _specToRaft;
  mapping(uint256 => uint256) private _badgeToRaft;

  constructor(address _badgesAddress, address _raftAddress) {
    badgesAddress = _badgesAddress;
    raftAddress = _raftAddress;
  }

  // restrict to only owner
  function setBadgesAddress(address _newBadgesAddress) public {
    badgesAddress = _newBadgesAddress;
  }

  function getRaftTokenId(string memory _specUri) public view returns (uint256) {
    return _specToRaft[_specUri];
  }

  function setBadgeToRaft(uint256 _badgeId, uint256 _raftTokenId) public {
    _badgeToRaft[_badgeId] = _raftTokenId;
  }

  function specIsRegistered(string memory _specUri) public view returns (bool) {
    return _specToRaft[_specUri] != 0;
  }

  function setSpecToRaft(string memory _specUri, uint256 _raftTokenId) public {
    _specToRaft[_specUri] = _raftTokenId;
  }

  function getRaftAddress() public view returns (address) {
    return raftAddress;
  }

  function setRaftAddress(address _newRaftAddress) public {
    raftAddress = _newRaftAddress;
  }
}
