// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.15;

import { ERC4973 } from "ERC4973/ERC4973.sol";

contract Badges is ERC4973 {
  event BadgeMinted(address indexed, uint256 tokenId);
  event SpecCreated(address indexed, string specUri);
  mapping(string => uint256) private _specToRaft;
  mapping(uint256 => uint256) private _badgeToRaft;

  constructor(
    string memory name,
    string memory symbol,
    string memory version
  ) ERC4973(name, symbol, version) {}

  function getHash(
    address from,
    address to,
    string calldata tokenURI
  ) public view returns (bytes32) {
    return _getHash(from, to, tokenURI);
  }

  function getTokenIdFromHash(bytes32 hash) public pure returns (uint256) {
    return uint256(hash);
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
    emit BadgeMinted(from, tokenId);
    return tokenId;
  }

  function createSpecAsRaftOwner(string memory specUri, uint256 raftTokenId) external {
    require(_specToRaft[specUri] == 0, "createSpecAsRaftOwner: spec already registered");
    _specToRaft[specUri] = raftTokenId;
    emit SpecCreated(msg.sender, specUri);
  }

  function checkIfSpecExists(string calldata specUri) public view returns (bool) {
    return _specToRaft[specUri] != 0;
  }
}
