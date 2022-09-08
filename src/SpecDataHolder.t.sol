// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import { IERC4973 } from "ERC4973/interfaces/IERC4973.sol";
import { Badges } from "./Badges.sol";
import { SpecDataHolder } from "./SpecDataHolder.sol";
import { Raft } from "./Raft.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UUPSProxy is ERC1967Proxy {
  constructor(address _implementation, bytes memory _data) ERC1967Proxy(_implementation, _data) {}
}

contract SpecDataHolderTest is Test {
  Badges badgesImplementationV1;
  SpecDataHolder specDataHolderImplementationV1;
  Raft raftImplementationV1;

  UUPSProxy badgesProxy;
  UUPSProxy raftProxy;
  UUPSProxy specDataHolderProxy;

  Badges badgesWrappedProxyV1;
  Raft raftWrappedProxyV1;
  SpecDataHolder specDataHolderWrappedProxyV1;

  address passiveAddress = 0x0f6A79A579658E401E0B81c6dde1F2cd51d97176;
  uint256 passivePrivateKey = 0xad54bdeade5537fb0a553190159783e45d02d316a992db05cbed606d3ca36b39;
  uint256 randomPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
  string specUri;

  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  function setUp() public {
    address to = address(this);
    badgesImplementationV1 = new Badges();
    specDataHolderImplementationV1 = new SpecDataHolder();
    raftImplementationV1 = new Raft();

    badgesProxy = new UUPSProxy(address(badgesImplementationV1), "");
    raftProxy = new UUPSProxy(address(raftImplementationV1), "");
    specDataHolderProxy = new UUPSProxy(address(specDataHolderImplementationV1), "");

    badgesWrappedProxyV1 = Badges(address(badgesProxy));
    raftWrappedProxyV1 = Raft(address(raftProxy));
    specDataHolderWrappedProxyV1 = SpecDataHolder(address(specDataHolderProxy));

    badgesWrappedProxyV1.initialize("Badges", "BADGES", "0.1.0", to, address(specDataHolderProxy));
    raftWrappedProxyV1.initialize(to, "Raft", "RAFT");
    specDataHolderWrappedProxyV1.initialize(address(raftProxy), to);
  }

  function createRaft() public returns (uint256) {
    address to = address(this);
    address from = address(0);

    vm.expectEmit(true, true, true, false);
    uint256 raftTokenId = raftWrappedProxyV1.mint(to, "some uri");
    emit Transfer(from, to, raftTokenId);

    assertEq(raftTokenId, 1);
    assertEq(raftWrappedProxyV1.balanceOf(to), 1);
    return raftTokenId;
  }

  // set Raft
  function testSetRaft() public {
    createRaft();
    address newRaftAddress = vm.addr(randomPrivateKey);
    specDataHolderWrappedProxyV1.setRaftAddress(newRaftAddress);
    assertEq(specDataHolderWrappedProxyV1.getRaftAddress(), newRaftAddress);
  }

  function testSetRaftAsNonOwner() public {
    createRaft();
    address newRaftAddress = vm.addr(randomPrivateKey);
    address attacker = vm.addr(randomPrivateKey);
    vm.prank(attacker);
    vm.expectRevert(bytes("Ownable: caller is not the owner"));
    specDataHolderWrappedProxyV1.setRaftAddress(newRaftAddress);
  }

  function testGetRaft() public {
    createRaft();
    specDataHolderWrappedProxyV1.getRaftAddress();
    assertEq(specDataHolderWrappedProxyV1.getRaftAddress(), address(raftProxy));
  }

  function testGetRaftTokenId() public {
    uint256 raftTokenId = createRaft();
    badgesWrappedProxyV1.createSpec(specUri, raftTokenId, 0);
    assertEq(specDataHolderWrappedProxyV1.isSpecRegistered(specUri), true);
    assertEq(specDataHolderWrappedProxyV1.getRaftTokenId(specUri), 1);
  }

  function testSetBadgesAddress() public {
    assertEq(specDataHolderWrappedProxyV1.getBadgesAddress(), address(0));
    address randomAddress = vm.addr(randomPrivateKey);

    specDataHolderWrappedProxyV1.setBadgesAddress(randomAddress);
    assertEq(specDataHolderWrappedProxyV1.getBadgesAddress(), randomAddress);
  }

  function testSetBadgesAddressAsNonOwner() public {
    assertEq(specDataHolderWrappedProxyV1.getBadgesAddress(), address(0));
    address randomAddress = vm.addr(randomPrivateKey);
    vm.prank(randomAddress);
    vm.expectRevert(bytes("Ownable: caller is not the owner"));
    specDataHolderWrappedProxyV1.setBadgesAddress(randomAddress);
  }

  // setBadgeToRaft

  // isSpecRegistered

  // setSpecToRaft

  // getRaftOwner

  // transfer ownership

  // transfer ownership as non-owner
}
