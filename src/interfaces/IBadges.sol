// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.16;

interface IBadges {
  function safeCheckAgreement(
    address,
    address,
    string calldata,
    bytes calldata
  ) external view returns (uint256);

  function mint(address, string memory) external returns (uint256);

  function setUsedHashId(uint256) external;

  function setVoucherHashId(uint256, uint256) external;
}
