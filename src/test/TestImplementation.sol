// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

contract TestImplementation {
  string public greet = "Hello World!";

  function getGreeting() public view returns (string memory) {
    return greet;
  }
}
