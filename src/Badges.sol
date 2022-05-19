// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import {ERC4973} from "ERC4973/ERC4973.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

string constant uri = "https://ipfs.io/ipfs/QmdoUaYzKCMUmeH473amYJNyFrL1a6gtccQ5rYsqqeHBsC";

contract Badges is ERC4973 {
	using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  constructor(
    string memory name,
    string memory symbol
  ) ERC4973(name, symbol) {}

  function mint(
    address to
  ) external returns (uint256) {
    uint256 newTokenId = _tokenIds.current();
		_mint(to, newTokenId, uri);
    _tokenIds.increment();
    return newTokenId;
  }
}
