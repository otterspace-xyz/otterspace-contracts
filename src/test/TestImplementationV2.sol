// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

contract TestImplementationV2 {
  string public greetV2 = "Hello World V2!";

  function getGreetingV2() public view returns (string memory) {
    return greetV2;
  }
}
