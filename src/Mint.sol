// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import { BadgeStorage } from "./BadgeStorage.sol";
import { Utils } from "./Utils.sol";
import { IERC4973 } from "ERC4973/interfaces/IERC4973.sol";

abstract contract Mint is IERC4973, BadgeStorage, Utils {
  function mint(address _to, string memory _uri) internal virtual returns (uint256) {
    uint256 raftTokenId = specDataHolder.getRaftTokenId(_uri);
    bytes32 hash = getBadgeIdHash(_to, _uri);
    uint256 tokenId = uint256(hash);
    // only registered specs can be used for minting
    require(raftTokenId != 0, "mint: spec is not registered");
    require(!exists(tokenId), "mint: tokenID exists");

    balances[_to] += 1;
    owners[tokenId] = _to;
    tokenURIs[tokenId] = _uri;

    emit Transfer(address(0), _to, tokenId);

    specDataHolder.setBadgeToRaft(tokenId, raftTokenId);
    return tokenId;
  }
}
