// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.7;

interface ISpecDataHolder {
  function getRaftOwner(uint256) external view returns (address);

  function specIsRegistered(string memory) external view returns (bool);

  function setSpecToRaft(string memory, uint256) external;

  function getRaftAddress() external view returns (address);

  function getRaftTokenId(string memory) external view returns (uint256);

  function setBadgeToRaft(uint256, uint256) external;
}
