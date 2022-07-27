// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface RaftInterface is IERC721 {
  function createSpec(string memory specUri, uint256 raftTokenId) external;
}
