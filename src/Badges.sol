// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import { ERC4973 } from "ERC4973/ERC4973.sol";

string constant uri = "https://ipfs.io/ipfs/QmdjBDRJLhv3aV3a1KhSAU3ChShK8oYgbX6kGa5Ln3AXn2";

contract Badges is ERC4973 {
  uint256 tokenId;
  constructor() ERC4973("Otterspace Badges", "OTTER") {}
  function mint(
    address to
  ) external returns (uint256) {
    super._mint(to, tokenId, uri);
    tokenId++;
    return tokenId-1;
  }

}
