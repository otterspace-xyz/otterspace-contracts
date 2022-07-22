// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.15;

import { ERC4973 } from "ERC4973/ERC4973.sol";
import { Raft } from "./Raft.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Badges is ERC4973, Ownable {
  event BadgeMinted(address indexed from, address indexed to, string specUri, uint256 tokenId);
  event SpecCreated(address indexed to, string specUri, uint256 indexed raftTokenId, address indexed raftAddress);

  mapping(string => uint256) private _specToRaft;
  mapping(uint256 => uint256) private _badgeToRaft;

  Raft private _raft;

  constructor(
    string memory name,
    string memory symbol,
    string memory version,
    address raftAddress,
    address nextOwner
  ) ERC4973(name, symbol, version) {
    _raft = Raft(raftAddress);
    transferOwnership(nextOwner);
  }

  function getRaftAddress() external view returns (address) {
    return address(_raft);
  }

  function setRaftAddress(address newRaftAddress) external onlyOwner {
    _raft = Raft(newRaftAddress);
  }

  function getHash(
    address from,
    address to,
    string calldata tokenURI
  ) public view returns (bytes32) {
    return _getHash(from, to, tokenURI);
  }

  function mintAuthorizedBadge(
    address from,
    string calldata specUri,
    bytes calldata signature
  ) public returns (uint256) {
    uint256 raftTokenId = _specToRaft[specUri];

    // only registered specs can be used for minting
    require(raftTokenId != 0, "mintAuthorizedBadge: spec is not registered");

    // if we use this.take() it will pass in this contract's address as msg.sender
    // so we use delegatecall to make sure we use the caller's address as msg.sender
    (bool success, bytes memory data) = address(this).delegatecall(
      abi.encodeWithSignature("take(address,string,bytes)", from, specUri, signature)
    );

    if (!success) {
      revert("mintAuthorizedBadge: badge minting failed");
    }

    uint256 tokenId = abi.decode(data, (uint256));
    _badgeToRaft[tokenId] = raftTokenId;

    emit BadgeMinted(from, msg.sender, specUri, tokenId);

    return tokenId;
  }

  function createSpecAsRaftOwner(string memory specUri, uint256 raftTokenId) external {
    require(_raft.ownerOf(raftTokenId) == msg.sender, "createSpecAsRaftOwner: unauthorized");
    require(_specToRaft[specUri] == 0, "createSpecAsRaftOwner: spec already registered");

    _specToRaft[specUri] = raftTokenId;

    emit SpecCreated(msg.sender, specUri, raftTokenId, address(_raft));
  }

  function getRaftTokenIdOf(string calldata specUri) external view returns (uint256) {
    return _specToRaft[specUri];
  }
}
