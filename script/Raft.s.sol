// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "forge-std/Script.sol";
import "../src/Raft.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UUPSProxy is ERC1967Proxy {
  constructor(address _implementation, bytes memory _data) ERC1967Proxy(_implementation, _data) {}
}

contract DeployUUPS is Script {
  UUPSProxy proxy;
  Raft wrappedProxyV1;

  function run() public {
    vm.startBroadcast();

    address to = address(0x29Dd7F6C6acAEcd4027D384736e90AE4f02C57c6);
    Raft implementationV1 = new Raft();

    // deploy proxy contract and point it to implementation
    proxy = new UUPSProxy(address(implementationV1), "");

    // wrap in ABI to support easier calls
    wrappedProxyV1 = Raft(address(proxy));
    wrappedProxyV1.initialize(address(to), "Raft", "RAFT");
    vm.stopBroadcast();
  }
}
