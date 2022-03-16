//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract OtterBadge is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private nextBadgeId;

    event BadgeMinted(
        address from,
        address to,
        uint256 tokenId,
        string tokenURI,
        string name,
        string group,
        uint8 level
    );

    constructor() ERC721("Otterspace Badge", "OTTER") {}

    // Issues: anyone can mint even an attacker, tokenURI can be arbitrary including name, group & level params
    // Could mind a "Badge Collection" and ensure that collectionId exists
    // How do we restrict bad actors from minting? whitelisting?
    function mintBadge(
        address receiver,
        string memory tokenURI,
        string memory name,
        string memory group,
        uint8 level
    ) public returns (uint256) {
        nextBadgeId.increment();
        uint256 tokenId = nextBadgeId.current();

        _safeMint(receiver, tokenId);
        _setTokenURI(tokenId, tokenURI);

        emit BadgeMinted(
            msg.sender,
            receiver,
            tokenId,
            tokenURI,
            name,
            group,
            level
        );

        return tokenId;
    }
}
