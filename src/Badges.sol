// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.15;

import {ERC4973Permit} from "ERC4973/ERC4973Permit.sol";

contract Badges is ERC4973Permit {
  constructor(
    string memory name,
    string memory symbol,
    string memory version
  ) ERC4973Permit(name, symbol, version) {}
}