// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./YardNFTWrapper.tokenURI.t.sol";

contract YardNFTWrapperApproveTransferFromSafeTransferFromTest is YardNFTWrapperTokenURITest {
    uint256 private wrappedID;

    modifier wrapToAlice() {
        vm.prank(pair);
        wrappedID = yardNFTWrapper.wrap(ERC721(cryptoPunks), validId, alice);

        _;
    }

    modifier release() {
        vm.prank(pair);
        yardNFTWrapper.release(wrappedID);

        _;
    }

    function testApproveUnreleasedID() public setFactoryAndPair wrapToAlice {
        vm.prank(alice);
        vm.expectRevert();
        yardNFTWrapper.approve(bob, wrappedID);
    }

    function testApproveReleasedID() public setFactoryAndPair wrapToAlice release {
        vm.prank(alice);
        yardNFTWrapper.approve(bob, wrappedID);
        assertTrue(yardNFTWrapper.getApproved(wrappedID) == bob);
    }

    function testTransferFromUnreleasedID() public setFactoryAndPair wrapToAlice {
        vm.prank(alice);
        vm.expectRevert();
        yardNFTWrapper.transferFrom(alice, bob, wrappedID);
    }

    function testTransferFromReleasedID() public setFactoryAndPair wrapToAlice release {
        vm.prank(alice);
        yardNFTWrapper.transferFrom(alice, bob, wrappedID);
        assertTrue(yardNFTWrapper.ownerOf(wrappedID) == bob);
    }

    function testSafeTransferFromUnreleasedID() public setFactoryAndPair wrapToAlice {
        vm.prank(alice);
        vm.expectRevert();
        yardNFTWrapper.safeTransferFrom(alice, bob, wrappedID);
    }

    function testSafeTransferFromReleasedID() public setFactoryAndPair wrapToAlice release {
        vm.prank(alice);
        yardNFTWrapper.safeTransferFrom(alice, bob, wrappedID);
        assertTrue(yardNFTWrapper.ownerOf(wrappedID) == bob);
    }
}