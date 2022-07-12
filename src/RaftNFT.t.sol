// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import { RaftNFT } from "./RaftNFT.sol";

contract RaftNFTTest is Test {
    RaftNFT r;

  

    address fromAddress = 0x0f6A79A579658E401E0B81c6dde1F2cd51d97176;
    uint256 fromPrivateKey = 0xad54bdeade5537fb0a553190159783e45d02d316a992db05cbed606d3ca36b39;

    address toAddress = 0xB2DDDD291289EfF4715F6e84CdB3D845a93037A6;
    uint256 toPrivateKey = 0x55b7b79aa0a71a634d00343ecb270adc0105d11566c7fcafa9381272d8d26554;

    function setUp() public {
        r = new RaftNFT();
    }

    function testConstructorParams() public {

    }

    


}