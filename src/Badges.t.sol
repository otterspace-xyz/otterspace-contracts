// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import { Badges } from "./Badges.sol";
import { ERC4973Permit } from "ERC4973/ERC4973Permit.sol";

contract BadgesTest is Test {
    Badges b;

    string constant name = "Name";
    string constant symbol = "Symbol";
    string constant version = "V1";

    address fromAddress = 0x0f6A79A579658E401E0B81c6dde1F2cd51d97176;
    uint256 fromPrivateKey = 0xad54bdeade5537fb0a553190159783e45d02d316a992db05cbed606d3ca36b39;

    address toAddress = 0xB2DDDD291289EfF4715F6e84CdB3D845a93037A6;
    uint256 toPrivateKey = 0x55b7b79aa0a71a634d00343ecb270adc0105d11566c7fcafa9381272d8d26554;

    function setUp() public {
        b = new Badges(name, symbol, version);
    }

    function testConstructorParams() public {
        assertEq(b.name(), name);
        assertEq(b.symbol(), symbol);
    }

    function testMintWithPermission() public {
        string memory tokenURI = "https://some-token-uri.com";
        bytes32 hash = b.getHash(fromAddress, toAddress, tokenURI);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(fromPrivateKey, hash);

        vm.prank(toAddress);
        bytes memory signature = abi.encodePacked(r, s, v);
        uint256 tokenId = b.mintWithPermission(fromAddress, tokenURI, signature);

        assertEq(tokenId, 0);
    }

    function testMintWithPermissionTwice() public {
        string memory tokenURI = "https://some-token-uri.com";
        bytes32 hash = b.getHash(fromAddress, toAddress, tokenURI);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(fromPrivateKey, hash);

        vm.prank(toAddress);
        bytes memory signature = abi.encodePacked(r, s, v);
        uint256 tokenId = b.mintWithPermission(fromAddress, tokenURI, signature);

        assertEq(tokenId, 0);

        tokenURI = "https://some-other-token-uri.com";
        hash = b.getHash(fromAddress, toAddress, tokenURI);
        (v, r, s) = vm.sign(fromPrivateKey, hash);

        vm.prank(toAddress);
        signature = abi.encodePacked(r, s, v);
        tokenId = b.mintWithPermission(fromAddress, tokenURI, signature);

        assertEq(tokenId, 1);
    }
}