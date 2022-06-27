// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Badges} from "./Badges.sol";

// rename to IssuerRegistry.sol? or a better name?
contract BadgeVendor {
  // a badge spec is a JSON blob representing the design of the badge to be minted and also uploaded to IPFS
  // a badge spec is fully unique and non-fungible - should THIS be a $ROMP token instead?
  mapping(string => uint256) private _badgeSpecOwners;

  ERC721 _romp; // is there a better way?
  Badges _badges; // is there a better way?

  // necessary?
  event BadgeSpecCreated(uint256 indexed rompTokenId, address owner, string tokenURI);

  // necessary?
  event BadgeMinted(address indexed owner, uint256 indexed tokenId, string tokenURI);

  constructor (
    address rompTokenAddress,
    address badgesAddress
  ) {
    _romp = ERC721(rompTokenAddress);
    _badges = Badges(badgesAddress);
  }

  // creates a spec and create an association of a $ROMP to specs created
  function createBadgeSpec(
    uint256 tokenId,
    string calldata tokenURI
  ) external {
    // authorize that only $ROMP token holder can create new specs
    require(msg.sender == _romp.ownerOf(tokenId), "createBadgeSpec: unauthorized");

    // register the spec owner
    _badgeSpecOwners[tokenURI] = tokenId;

    // emit event that badge spec was created, indexed over romp token ID
    emit BadgeSpecCreated(tokenId, msg.sender, tokenURI);
  }

  function ownerOfSpec(string calldata tokenUri) public view returns (uint256) {
    return _badgeSpecOwners[tokenUri];
  }

  function claimBadge(
    address fromAddress,
    string calldata tokenURI,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256) {
    require(_badgeSpecOwners[tokenURI] != 0, "claimBadge: unauthorized");

    bytes memory signature = abi.encodePacked(r, s, v);

    uint256 tokenId = _badges.mintWithPermission(fromAddress, tokenURI, signature);

    emit BadgeMinted(msg.sender, tokenId, tokenURI);

    return tokenId;
  }
}


/*
ROMP as spec
  - mint ROMP Token to Spec owner with badge spec as URI
  - Validate fromAddress being owner of supplied tokenId
  - Looking up URI for tokenId and then mint badge
  Pros
    -
  Cons
    - If ROMP is transferred after voucher and before claiming, mint will fail. New issuer must reissue vouchers

ROMP as DAO
  - set tokenURI as daoURI with EIP4824, pointing to otterspace API
  - dao owner is also badge issuer (for now)
  -
  Pros
  Cons
    - how to create authorization?
*/