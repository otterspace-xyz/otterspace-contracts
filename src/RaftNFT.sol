// contracts/NFT.sol
// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// import "hardhat/console.sol";

contract RaftNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    bool privateBeta;
    address _owner;

    constructor() ERC721("Raft NFT", "RAFT") {
      privateBeta = true;
      _owner = msg.sender;
    }

    function createToken(address nftRecipient, string memory tokenURI) external returns (uint) {
        if (privateBeta) {
          require(msg.sender == _owner, "Only the owner can create tokens");
        }
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(nftRecipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

    function updatePrivateBetaStatus(bool status) onlyOwner external {
      privateBeta = status;
    }

    function removeTokenFromUser(uint256 tokenId) onlyOwner external {
        _burn(tokenId);
    }
}