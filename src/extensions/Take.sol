// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.16;
import { IBadges } from "../interfaces/IBadges.sol";

contract Take {
  address internal badgesAddress;

  function setBadgesAddress(address _badgesAddress) external {
    badgesAddress = _badgesAddress;
  }

  /**
   * @notice Allows a user to mint a badge from a voucher
   * @dev Take is called by somebody who has already been added to an allow list.
   * @param _from the person who issued the voucher, who is permitting them to mint the badge.
   * @param _uri the uri of the badge spec
   * @param _signature the signature used to verify that the person minting has permission from the issuer
   */

  // we have t pass in _active since msg.sender the badges contract
  function take(
    address _active,
    address _from,
    string calldata _uri,
    bytes calldata _signature
  ) external returns (uint256) {
    IBadges badgesContract = IBadges(badgesAddress);
    require(msg.sender != _from, "take: cannot take from self");

    uint256 voucherHashId = badgesContract.safeCheckAgreement(_active, _from, _uri, _signature);
    uint256 tokenId = badgesContract.mint(_active, _uri);

    // we can't use the two storage variables below directly with interfaces, so we need functions
    badgesContract.setUsedHashId(voucherHashId);
    badgesContract.setVoucherHashId(tokenId, voucherHashId);
    return tokenId;
  }
}
