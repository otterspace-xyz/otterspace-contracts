// contracts/BoxV2.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Raft.sol";

contract RaftV2 is Raft {
  // Increments the stored value by 1
  function getVersion() public pure returns (uint256) {
    return 2;
  }
}
