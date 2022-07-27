// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.15;

import { ERC4973 } from "ERC4973/ERC4973.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./BadgesDataHolder.sol";

contract Badges is ERC4973, Ownable {
  event BadgeMinted(address indexed to, string specUri, uint256 tokenId);
  event SpecCreated(address indexed to, string specUri, uint256 indexed raftTokenId, address indexed raftAddress);

  BadgesDataHolder private dataHolder;

  constructor(
    string memory name,
    string memory symbol,
    string memory version,
    address nextOwner,
    address dataHolderAddress
  ) ERC4973(name, symbol, version) {
    transferOwnership(nextOwner);
    dataHolder = BadgesDataHolder(dataHolderAddress);
  }

  // The owner can call this once only. They should call this when the contract is first deployed.
  function setDataHolder(address _dataHolder) external onlyOwner {
    // require(address(dataHolder) == address(0x0));
    dataHolder = BadgesDataHolder(_dataHolder);
  }

  function getDataHolderAddress() public view returns (address) {
    return address(dataHolder);
  }

  function getHash(
    address from,
    address to,
    string calldata tokenURI
  ) public view returns (bytes32) {
    return _getHash(from, to, tokenURI);
  }

  function _mint(
    address to,
    uint256 tokenId,
    string memory uri
  ) internal override returns (uint256) {
    uint256 raftTokenId = dataHolder.getRaftTokenId(uri);

    // only registered specs can be used for minting
    require(raftTokenId != 0, "_mint: spec is not registered");
    super._mint(to, tokenId, uri);
    dataHolder.setBadgeToRaft(tokenId, raftTokenId);

    emit BadgeMinted(msg.sender, uri, tokenId);
    return tokenId;
  }

  function createSpecAsRaftOwner(string memory specUri, uint256 raftTokenId) external {
    address raftOwner = dataHolder.getRaftOwner(raftTokenId);
    require(raftOwner == msg.sender, "createSpecAsRaftOwner: unauthorized");
    require(!dataHolder.specIsRegistered(specUri), "createSpecAsRaftOwner: spec already registered");

    dataHolder.setSpecToRaft(specUri, raftTokenId);

    emit SpecCreated(msg.sender, specUri, raftTokenId, dataHolder.getRaftAddress());
  }
}
