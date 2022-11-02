// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;
import { BadgeDataHolder } from "./BadgeDataHolder.sol";
import { SignatureCheckerUpgradeable } from "@openzeppelin-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import { ISpecDataHolder } from "./interfaces/ISpecDataHolder.sol";
import { IERC721Metadata } from "./interfaces/IERC721Metadata.sol";

bytes32 constant AGREEMENT_HASH = keccak256("Agreement(address active,address passive,string tokenURI)");

contract Utils is BadgeDataHolder {
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
    require(!getUsedVoucherHash(voucherHashId), "safeCheckAgreement: already used");
    return voucherHashId;
  }

  function getVoucherHash(uint256 _tokenId) public view virtual returns (uint256) {
    return voucherHashIds[_tokenId];
  }

  function getDataHolderAddress() external view returns (address) {
    return address(specDataHolder);
  }

  /**
   * @notice Allows the Badges contract to communicate with the SpecDataHolder contract
   * @param _dataHolder address of the SpecDataHolder contract
   */
  function setDataHolder(address _dataHolder) external virtual onlyOwner {
    specDataHolder = ISpecDataHolder(_dataHolder);
  }
}
