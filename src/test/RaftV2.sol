// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.15;

import "../Raft.sol";

contract RaftV2 is Raft {
  uint256 public myNewVar;
  bool varIsSet;

  function getVersion() external pure returns (uint256) {
    return 2;
  }

  // pattern where we will do a one-time initialization of a new variable
  function setNewVar() public {
    require(!varIsSet, "Var is already set");
    myNewVar = 9;
    varIsSet = true;
  }
}
