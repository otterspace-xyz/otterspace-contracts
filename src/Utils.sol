// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;
import { BadgeStorage } from "./BadgeStorage.sol";
import { SignatureCheckerUpgradeable } from "@openzeppelin-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";

bytes32 constant AGREEMENT_HASH = keccak256("Agreement(address active,address passive,string tokenURI)");

contract Utils is BadgeStorage {
  // TODO: consider moving modifiers to their own file
  modifier senderIsRaftOwner(uint256 _raftTokenId, string memory calledFrom) {
    string memory message = string(abi.encodePacked(calledFrom, ": unauthorized"));
    require(specDataHolder.getRaftOwner(_raftTokenId) == msg.sender, message);
    _;
  }

  modifier tokenExists(uint256 _badgeId) {
    require(owners[_badgeId] != address(0), "tokenExists: token doesn't exist");
    _;
  }

  function getBadgeIdHash(address _to, string memory _uri) public view virtual returns (bytes32) {
    return keccak256(abi.encode(_to, _uri));
  }

  function exists(uint256 _tokenId) internal view virtual returns (bool) {
    return owners[_tokenId] != address(0);
  }

  function getAgreementHash(
    address _from,
    address _to,
    string calldata _uri
  ) public view virtual returns (bytes32) {
    bytes32 structHash = keccak256(abi.encode(AGREEMENT_HASH, _from, _to, keccak256(bytes(_uri))));
    return _hashTypedDataV4(structHash);
  }

  function safeCheckAgreement(
    address _active,
    address _passive,
    string calldata _uri,
    bytes calldata _signature
  ) internal virtual returns (uint256) {
    bytes32 hash = getAgreementHash(_active, _passive, _uri);
    uint256 voucherHashId = uint256(hash);

    require(
      SignatureCheckerUpgradeable.isValidSignatureNow(_passive, hash, _signature),
      "safeCheckAgreement: invalid signature"
    );
    require(!getUsedHashId(voucherHashId), "safeCheckAgreement: already used");
    return voucherHashId;
  }

  function getVoucherHash(uint256 _tokenId) public view virtual returns (uint256) {
    return voucherHashIds[_tokenId];
  }

  function getDataHolderAddress() external view returns (address) {
    return address(specDataHolder);
  }
}
