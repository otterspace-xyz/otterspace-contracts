// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.15;

import {ERC4973Permit} from "ERC4973/ERC4973Permit.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

contract Badges is ERC4973Permit {

  bytes32 private immutable _CHAIN_CLAIM_TYPEHASH =
    keccak256("Claim(address chainedAddress)");

  constructor(
    string memory name,
    string memory symbol,
    string memory version
  ) ERC4973Permit(name, symbol, version) {}


  function isValidIssuerSig(
    address claimantAddress,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public view returns (bool) {
    bytes32 hash = genDataHash(claimantAddress);
    address signer = ECDSA.recover(hash, v, r, s);
    // bool isValidSig = SignatureChecker.isValidSignatureNow(claimantAddress, hash);

    // console.log("isValidSig", isValidSig);
    return signer == claimantAddress;
  }

  /// @notice On chain generation for a valid EIP-712 hash
  /// @param chainedAddress the address that has been signed
  /// @return The typed data hash
  function genDataHash(address chainedAddress) public view returns (bytes32) {
    bytes32 structHash = keccak256(
      abi.encode(_CHAIN_CLAIM_TYPEHASH, chainedAddress)
    );

    return _hashTypedDataV4(structHash);
  }

}