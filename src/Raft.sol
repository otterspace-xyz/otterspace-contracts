// contracts/NFT.sol
// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Raft is ERC721URIStorage, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor(address owner, string memory name, string memory symbol) ERC721(name, symbol) {
      transferOwnership(owner);
      _pause();
    }

    function mint(address recipient, string memory tokenURI) external returns (uint) { 
        require(msg.sender == owner() || !paused(), "mint: unauthorized to mint");
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}