// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import {Badges} from "./Badges.sol";
import {ChainClaim} from "./ChainClaim.sol";

struct Vendor {
  address issuer;
  string name;
}

contract BadgeVendor is ChainClaim {
  constructor(
    Vendor memory v
  ) ChainClaim(v.issuer, v.name) {}

	function _genDataHash(
		address chainedAddress
	) external view returns (bytes32) {
		return genDataHash(chainedAddress);
  }

  function takeBadge(
    address collection,
    address issuedAddress,
    uint8[2] memory v,
    bytes32[2] memory r,
    bytes32[2] memory s
  ) external returns (uint256) {
    require(
      claim(issuedAddress, msg.sender, v, r, s),
      "BadgeVendor: Failed taking Badge"
    );
    Badges badges = Badges(collection);
    return badges.mint(msg.sender);
  }
}
