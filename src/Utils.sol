// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;
import { BadgeStorage } from "./BadgeStorage.sol";

contract Utils is BadgeStorage {
  function getBadgeIdHash(address _to, string memory _uri) public view virtual returns (bytes32) {
    return keccak256(abi.encode(_to, _uri));
  }

  function exists(uint256 _tokenId) internal view virtual returns (bool) {
    return owners[_tokenId] != address(0);
  }
}
