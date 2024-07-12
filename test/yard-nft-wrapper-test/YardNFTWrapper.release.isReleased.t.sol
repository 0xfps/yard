// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./YardNFTWrapper.tokenURI.t.sol";

contract YardNFTWrapperReleaseIsReleasedTest is YardNFTWrapperTokenURITest {
    function testReleaseWrappedIDByInvalidPair() public setFactoryAndPair {
        vm.prank(pair);
        uint256 wrappedID = yardNFTWrapper.wrap(ERC721(cryptoPunks), validId, alice);

        assertFalse(yardNFTWrapper.isReleased(wrappedID));

        vm.prank(hacker);
        vm.expectRevert();
        yardNFTWrapper.release(wrappedID);
    }

    function testReleaseWrappedIDByValidPair() public setFactoryAndPair {
        vm.prank(pair);
        uint256 wrappedID = yardNFTWrapper.wrap(ERC721(cryptoPunks), validId, alice);
        bool isReleased = yardNFTWrapper.isReleased(wrappedID);

        assertFalse(isReleased);

        vm.prank(pair);
        yardNFTWrapper.release(wrappedID);

        isReleased = yardNFTWrapper.isReleased(wrappedID);
        assertTrue(isReleased);
    }
}