// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.15;

import "./SpecDataHolder.sol";

contract SpecDataHolderV2 is SpecDataHolder {
  function getVersion() external pure returns (uint256) {
    return 2;
  }
}
