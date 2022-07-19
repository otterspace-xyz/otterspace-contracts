// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.15;

import { ERC4973 } from "ERC4973/ERC4973.sol";
import { Badges } from "./Badges.sol";
import { Raft } from "./Raft.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import { SignatureChecker } from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
bytes32 constant CREATE_SPEC_PERMIT_HASH = keccak256("CreateSpecPermit(address to,uint256 raftTokenId)");

contract BadgesController is EIP712 {
  mapping(string => uint256) private _specToRaft;
  mapping(uint256 => uint256) private _badgeToRaft;

  Badges _badges;
  Raft _raft;

  constructor(
    address badgesAddress,
    address raftAddress,
    string memory name,
    string memory version
  ) EIP712(name, version) {
    _badges = Badges(badgesAddress);
    _raft = Raft(raftAddress);
  }

  function mintBadge(
    address to,
    string calldata specUri,
    bytes calldata signature
  ) public returns (uint256) {
    // mint the badge
    uint256 tokenId = _badges.give(to, specUri, signature);

    //set the tokenId to the raft tokenId, so that we know what DAO this badge is associated with
    uint256 raftTokenId = _specToRaft[specUri];
    _badgeToRaft[tokenId] = raftTokenId;

    return tokenId;
  }

  function createSpecAsRaftOwner() public {
    
  }

  function checkIfSpecExists(string calldata specUri) public view returns (bool) {
    return _specToRaft[specUri] != 0;
  }
}
