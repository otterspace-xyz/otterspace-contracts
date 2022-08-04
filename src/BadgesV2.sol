// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

import "./Badges.sol";

contract BadgesV2 is Badges {
  function getVersion() external pure returns (uint256) {
    return 2;
  }
}
