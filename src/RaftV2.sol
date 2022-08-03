// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.15;

import "hardhat/console.sol";
import "./Raft.sol";

contract RaftV2 is Raft {
  function getVersion() external pure returns (uint256) {
    return 2;
  }
}
