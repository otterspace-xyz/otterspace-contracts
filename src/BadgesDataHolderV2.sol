// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.15;
import "./BadgesDataHolder.sol";

contract BadgesDataHolderV2 is BadgesDataHolder {
  ///@dev returns the contract version
  function contractVersion() external pure returns (uint256) {
    return 2;
  }
}
