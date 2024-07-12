// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./YardNFTWrapper.wrap.t.sol";

contract YardNFTWrapperUnwrapTest is YardNFTWrapperWrapTest {
    uint256 index;

    modifier wrapFirst(address receiver) {
        testAddProperPairShouldPass();
        vm.startPrank(pair);
        index = yardNFTWrapper.wrap(ERC721(cryptoPunks), validId, receiver);
        vm.stopPrank();

        _;
    }

    function testUnwrapByUnallowedPair(address hackers) public wrapFirst(alice) {
        vm.assume((hackers != pair) && (hackers != zero));
        vm.prank(hackers);
        vm.expectRevert();
        yardNFTWrapper.unwrap(index);

        assertTrue(yardNFTWrapper.ownerOf(index) == alice);
    }

    function testUnwrapByAllowedPair() public wrapFirst(bob) {
        bool isUnwrapped;

        vm.prank(pair);
        isUnwrapped = yardNFTWrapper.unwrap(index);

        assertTrue(isUnwrapped);
    }
}