// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title RAFT Contract
/// @author Otterspace
/// @notice The RAFT NFT gives the owner the ability to create a DAO within Otterspace
/// @dev Inherits from ERC721Enumerable so that we can access useful functions for
/// querying owners of tokens from the web app.
contract Raft is ERC721Enumerable, Ownable, Pausable {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  mapping(uint256 => string) private _tokenURIs;

  constructor(
    address nextOwner,
    string memory name,
    string memory symbol
  ) ERC721(name, symbol) {
    // Passing in the owner's address allows an EOA to deploy and set a multi-sig as the owner.
    transferOwnership(nextOwner);

    // pause the contract by default
    _pause();
  }

  function mint(address recipient, string memory uri) external returns (uint256) {
    // owners can always mint tokens
    // non-owners can only mint when the contract is unpaused
    require(msg.sender == owner() || !paused(), "mint: unauthorized to mint");
    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();

    _mint(recipient, newItemId);
    _tokenURIs[newItemId] = uri;

    return newItemId;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function setTokenURI(uint256 tokenId, string memory uri) public onlyOwner {
    require(_exists(tokenId), "_setTokenURI: URI set of nonexistent token");
    _tokenURIs[tokenId] = uri;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    return _tokenURIs[tokenId];
  }
}
