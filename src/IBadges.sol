// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.15;

import { IERC4973 } from "ERC4973/interfaces/IERC4973.sol";

interface IBadges is IERC4973 {
  function mintAuthorizedBadge(
    address from,
    string calldata uri,
    bytes calldata signature
  ) external returns (uint256);
}
