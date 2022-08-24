// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/ISpecDataHolder.sol";
import "@openzeppelin-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

// import "../../node_modules/hardhat/console.sol";

contract SpecDataHolder is UUPSUpgradeable, OwnableUpgradeable, ISpecDataHolder {
  mapping(string => uint256) private _specToRaft;
  mapping(uint256 => uint256) private _badgeToRaft;

  address private badgesAddress;
  address private raftAddress;

  modifier onlyBadgesContract() {
    require(msg.sender == badgesAddress, "unauthorized");
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  // check to see if the _specCreator (msg.sender) owns a badge that's associated with _raftTokenId
  function doesSenderOwnADaosBadge(address _specCreator, uint256 _raftTokenId) public view returns (bool) {
    ERC721EnumerableUpgradeable badgesInterface = ERC721EnumerableUpgradeable(badgesAddress);
    // return badgesInterface.ownerOf(_raftTokenId);
    // call `balanceOf(_specCreator)` to get the number of badges owned by _specCreator
    uint256 numBadges = badgesInterface.balanceOf(_specCreator);
    // for each badge owned by _specCreator, check if it's associated with _raftTokenId
    for (uint256 i = 0; i < numBadges; i++) {
      // get the tokenId of the badge
      uint256 tokenId = badgesInterface.tokenOfOwnerByIndex(_specCreator, i);
      // check to see if the tokenId is associated with _raftTokenId
      uint256 raftTokenId = _badgeToRaft[tokenId];
      // if the raft token id of the badge at index i is equal to _raftTokenId, return true
      // "true" means this means they mint a badge
      // otherwise, check the next badge
      if (raftTokenId == _raftTokenId) {
        return true;
      }
    }
  }

  function setBadgesAddress(address _badgesAddress) external virtual onlyOwner {
    badgesAddress = _badgesAddress;
  }

  function setRaftAddress(address _raftAddress) external virtual onlyOwner {
    raftAddress = _raftAddress;
  }

  function setBadgeToRaft(uint256 _badgeTokenId, uint256 _raftTokenId) external virtual onlyBadgesContract {
    _badgeToRaft[_badgeTokenId] = _raftTokenId;
  }

  function setSpecToRaft(string memory _specUri, uint256 _raftTokenId) external virtual {
    _specToRaft[_specUri] = _raftTokenId;
  }

  function getBadgesAddress() external view returns (address) {
    return badgesAddress;
  }

  function getRaftAddress() external view returns (address) {
    return raftAddress;
  }

  function getRaftTokenId(string memory _specUri) external view returns (uint256) {
    return _specToRaft[_specUri];
  }

  function isSpecRegistered(string memory _specUri) external view returns (bool) {
    return _specToRaft[_specUri] != 0;
  }

  function getRaftOwner(uint256 _raftTokenId) external view returns (address) {
    IERC721 raftInterface = IERC721(raftAddress);
    return raftInterface.ownerOf(_raftTokenId);
  }

  // Passing in the owner's address allows an EOA to deploy and set a multi-sig as the owner.
  function initialize(address _raftAddress, address _nextOwner) public initializer {
    __Ownable_init();
    raftAddress = _raftAddress;
    transferOwnership(_nextOwner);
    __UUPSUpgradeable_init();
  }

  // The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
  // Not implementing this function because it is used to check who is authorized
  // to update the contract, we're using onlyOwnerfor this purpose.
  function _authorizeUpgrade(address) internal override onlyOwner {}
}
