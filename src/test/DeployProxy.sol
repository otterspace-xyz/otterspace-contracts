// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

// Import OZ Proxy contracts
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { Vm } from "forge-std/Vm.sol";

contract DeployProxy {
  /// Cheatcodes address
  Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

  ProxyType public proxyType;

  address public proxyAddress;

  ERC1967Proxy public erc1967;

  TransparentUpgradeableProxy public uups;

  enum ProxyType {
    UUPS
  }

  function deploy(address implementation, bytes memory data) public returns (address) {
    if (proxyType == ProxyType.UUPS) {
      revert("UUPS proxies require an admin address");
    }
  }

  function deploy(address implementation) public returns (address) {
    if (proxyType == ProxyType.UUPS) {
      revert("UUPS proxies require an admin address");
    }
  }

  function deploy(
    address implementation,
    address admin,
    bytes memory data
  ) public returns (address) {
    if (proxyType == ProxyType.UUPS) {
      return deployUupsProxy(implementation, admin, data);
    }
  }

  function deploy(address implementation, address admin) public returns (address) {
    if (proxyType == ProxyType.UUPS) {
      bytes memory data;
      return deployUupsProxy(implementation, admin, data);
    }
  }

  function deployErc1967Proxy(address implementation, bytes memory data) public returns (address) {
    erc1967 = new ERC1967Proxy(implementation, data);
    proxyAddress = address(erc1967);
    vm.label(proxyAddress, "ERC1967 Proxy");
    return proxyAddress;
  }

  function deployUupsProxy(
    address implementation,
    address admin,
    bytes memory data
  ) public returns (address) {
    uups = new TransparentUpgradeableProxy(implementation, admin, data);
    proxyAddress = address(uups);
    vm.label(proxyAddress, "UUPS Proxy");
    return proxyAddress;
  }
}
