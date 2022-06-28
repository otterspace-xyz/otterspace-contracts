// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import {Badges} from "./Badges.sol";

contract BadgeVendor {
  Badges _badges;

  constructor (
    address badgesAddress
  ) {
    _badges = Badges(badgesAddress);
  }

  function claimBadge(
    address fromAddress,
    string calldata tokenURI,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256) {
    bytes memory signature = abi.encodePacked(r, s, v);

    uint256 tokenId = _badges.mintWithPermission(fromAddress, tokenURI, signature);

    return tokenId;
  }
}