// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.15;
import "../src/Badges.sol";

contract BadgesV2 is Badges {
  uint256 public version;

  function setVersion(uint256 version_) public returns (uint256) {
    version = version_;
  }

  function getVersion() public view returns (uint256) {
    return version;
  }
}
