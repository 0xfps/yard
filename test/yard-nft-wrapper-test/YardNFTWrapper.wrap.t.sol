// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./YardNFTWrapper.addPair.t.sol";

contract YardNFTWrapperWrapTest is YardNFTWrapperAddPairTest {
    modifier setUpFactoryAndPair() {
        testAddProperPairShouldPass();

        _;
    }

    function testWrapByInvalidPair(address hackers) public setUpFactoryAndPair {
        vm.assume((hackers != pair) && (hackers != zero));
        vm.prank(hackers);
        vm.expectRevert();

        yardNFTWrapper.wrap(ERC721(cryptoPunks), validId, hackers);
    }

    function testWrapToZeroAddress() public setUpFactoryAndPair {
        vm.prank(pair);
        vm.expectRevert();
        yardNFTWrapper.wrap(ERC721(cryptoPunks), validId, zero);
    }

    function testWrapInvalidID() public setUpFactoryAndPair {
        vm.prank(pair);
        vm.expectRevert();
        yardNFTWrapper.wrap(ERC721(cryptoPunks), invalidID, alice);
    }

    function testWrapInexistentToken() public setUpFactoryAndPair {
        vm.prank(pair);
        vm.expectRevert();
        yardNFTWrapper.wrap(ERC721(cryptoPunks), invalidID, alice);
    }

    function testWrapByApprovedPair(address properReceiver) public setUpFactoryAndPair {
        vm.assume(properReceiver != zero);
        vm.startPrank(pair);
        uint256 index;

        for (uint256 i; i < validCryptoPunkIDs.length; i++) {
            index = yardNFTWrapper.wrap(ERC721(cryptoPunks), validCryptoPunkIDs[i], properReceiver);
            address ownerOfWrappedNFT = yardNFTWrapper.ownerOf(index);
            assertTrue(ownerOfWrappedNFT == properReceiver);
        }

        vm.stopPrank();

        assertTrue(index == validCryptoPunkIDs.length - 1);
    }
}