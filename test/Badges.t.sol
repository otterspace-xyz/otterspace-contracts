// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import "../src/Badges.sol";

contract BadgesTest is Test {
    Badges b;

    function setUp() public {
        b = new Badges("Otter", "OTTR", "1.0.0");
    }

    // function testName() public {
    //     assertEq(b.name(), "Badges");
    // }

}
