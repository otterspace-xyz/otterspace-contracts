// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.16;

interface ITake {
  function take(
    address _active,
    address _passive,
    string calldata _uri,
    bytes calldata _signature
  ) external returns (uint256);

  function setBadgesAddress(address _badgesAddress) external;
}
