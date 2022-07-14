// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.15;

import { ERC4973 } from "ERC4973/ERC4973.sol";
import { Badges } from "./Badges.sol";
import { Raft } from "./Raft.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import { SignatureChecker } from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

bytes32 constant CREATE_SPEC_PERMIT_HASH = keccak256("CreateSpecPermit(address to,uint256 raftTokenId)");

contract BadgesController is EIP712 {
  mapping(string => bool) private _registeredSpecs; // todo:: find a better way to check a spec generally exists or not
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

  function getCreateSpecHash(address to, uint256 raftTokenId) public view returns (bytes32) {
    bytes32 structHash = keccak256(abi.encode(CREATE_SPEC_PERMIT_HASH, to, raftTokenId));
    return _hashTypedDataV4(structHash);
  }

  function registerSpec(
    string calldata specUri,
    uint256 raftTokenId,
    bytes calldata signature,
    bool selfMint
  ) public {
    // ✅ only if a DAO admin / raft owner has permitted via a valid signature, msg.sender can create new badge specs
    require(_specToRaft[specUri] == 0, "Spec already registered");

    bytes32 hash = getCreateSpecHash(msg.sender, raftTokenId);

    address raftOwner = _raft.ownerOf(raftTokenId);

    require(SignatureChecker.isValidSignatureNow(raftOwner, hash, signature), "registerSpec: invalid signature");

    _specToRaft[specUri] = raftTokenId;
    _registeredSpecs[specUri] = true;

    if (selfMint) {
      mintBadgeToSelf(specUri);
    }
  }

  // register a badge spec that can be used for minting
  function registerSpec(
    uint256 badgeTokenId,
    uint256 raftTokenId,
    string calldata specUri,
    bool selfMint
  ) public {
    // ✅ only someone with a badge in a certain dao can create new badge specs
    // ✅ user should be able to optionally self-mint the spec they just created as its first badge holder

    // spec should not be registered already
    require(_registeredSpecs[specUri] == false, "Spec already registered");
    // authorize the user that they are indeed the owner of this badge
    require(_badges.ownerOf(badgeTokenId) == msg.sender, "unauthorized");
    // make sure that the DAO associated to this badge is the same DAO that the new spec is being registered
    require(_badgeToRaft[badgeTokenId] == raftTokenId, "unauthorized");

    _specToRaft[specUri] = raftTokenId;
    _registeredSpecs[specUri] = true;

    if (selfMint) {
      mintBadgeToSelf(specUri);
    }
  }

  function mintBadgeToSelf(string calldata specUri) private returns (uint256) {
    bytes32 hash = _badges.getHash(msg.sender, msg.sender, specUri);
    uint256 index = uint256(hash);
    return _badges.mint(msg.sender, index, specUri);
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
}
