// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.15;

import { ERC4973 } from "ERC4973/ERC4973.sol";
import { Raft } from "./Raft.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DataHolder.sol";
import "./RaftInterface.sol";

contract Badges is ERC4973, Ownable {
  event BadgeMinted(address indexed to, string specUri, uint256 tokenId);
  event SpecCreated(address indexed to, string specUri, uint256 indexed raftTokenId, address indexed raftAddress);

  DataHolder private dataHolder;
  address public initialOwner;
  RaftInterface public raft;

  constructor(
    string memory name,
    string memory symbol,
    string memory version
  ) ERC4973(name, symbol, version) {
    initialOwner = msg.sender;
  }

  // The owner can call this once only. They should call this when the contract is first deployed.
  function setDataHolder(address _dataHolder) external {
    require(msg.sender == initialOwner);
    // require(address(dataHolder) == address(0x0));
    dataHolder = DataHolder(_dataHolder);
  }

  function setRaft(address _raftAddress) public {
    raft = RaftInterface(_raftAddress);
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
    address raftOwner = raft.ownerOf(raftTokenId);
    require(raftOwner == msg.sender, "createSpecAsRaftOwner: unauthorized");
    require(!dataHolder.specIsRegistered(specUri), "createSpecAsRaftOwner: spec already registered");

    dataHolder.setSpecToRaft(specUri, raftTokenId);

    emit SpecCreated(msg.sender, specUri, raftTokenId, dataHolder.getRaftAddress());
  }

  function getRaftTokenIdOf(string memory specUri) public view returns (uint256) {
    return dataHolder.getRaftTokenId(specUri);
  }

  function getRaftAddress() public view returns (address) {
    return dataHolder.getRaftAddress();
  }

  function setRaftAddress(address _newRaftAddress) public onlyOwner {
    require(msg.sender == initialOwner);
    dataHolder.setRaftAddress(_newRaftAddress);
  }
}
