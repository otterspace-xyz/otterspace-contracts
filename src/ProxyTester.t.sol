// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import { Vm } from "forge-std/Vm.sol";
import { DSTest } from "ds-test/test.sol";
import { console } from "forge-std/console.sol";
import { ProxyTester } from "./test/ProxyTester.sol";

import { TestImplementation } from "./test/TestImplementation.sol";
import { TestImplementationV2 } from "./test/TestImplementationV2.sol";

contract UpgradeTest is DSTest {
  ProxyTester proxy;

  TestImplementation impl;
  TestImplementationV2 implV2;

  address proxyAddress;

  address admin;

  Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

  function setUp() public {
    proxy = new ProxyTester();
    impl = new TestImplementation();
    admin = vm.addr(69);
  }

  function testDeployUUPS() public {
    proxy.setType("uups");
    proxyAddress = proxy.deploy(address(impl), admin);
    assertEq(proxyAddress, proxy.proxyAddress());
    assertEq(proxyAddress, address(proxy.uups()));
    bytes32 implSlot = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
    bytes32 proxySlot = vm.load(proxyAddress, implSlot);
    address addr;
    assembly {
      mstore(0, proxySlot)
      addr := mload(0)
    }
    assertEq(address(impl), addr);
  }

  function testUpgradeUUPS() public {
    testDeployUUPS();
    TestImplementationV2 newImplV2 = new TestImplementationV2();
    /// Since the admin is an EOA, it doesn't have an owner
    proxy.upgrade(address(newImplV2), admin, address(0));
    bytes32 implSlot = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
    bytes32 proxySlot = vm.load(proxyAddress, implSlot);
    address addr;
    assembly {
      mstore(0, proxySlot)
      addr := mload(0)
    }
    assertEq(address(newImplV2), addr);
    assertEq(newImplV2.getGreetingV2(), "Hello World V2!");
  }
}
