// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.15;

import { ERC4973 } from "ERC4973/ERC4973.sol";

contract Badges is ERC4973 {
  constructor(
    string memory name,
    string memory symbol,
    string memory version
  ) ERC4973(name, symbol, version) {}

  function getHash(
    address from,
    address to,
    string calldata tokenURI
  ) public view returns (bytes32) {
    return _getHash(from, to, tokenURI);
  }

  function getTokenIdFromHash(
    bytes32 hash
  ) public pure returns (uint256) {
    return uint256(hash);
  }
}
