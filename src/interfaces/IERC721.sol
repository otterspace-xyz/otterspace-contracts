// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

interface IERC721 {
  function ownerOf(uint256 tokenId) external view returns (address owner);
}