// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./YardNFTWrapper.t.sol";

contract YardNFTWrapperSetFactoryTest is YardNFTWrapperTest {
    function testSetFactoryByNonOwner() public {
        vm.prank(hacker);
        vm.expectRevert();
        yardNFTWrapper.setFactory(factory);
    }

    function testSetFactoryWithZeroAddressWhenFactoryNotSet() public {
        vm.prank(owner);
        vm.expectRevert();
        yardNFTWrapper.setFactory(zero);
    }

    function testSetFactoryShouldPass() public {
        vm.prank(owner);
        yardNFTWrapper.setFactory(factory);

        assertTrue(yardNFTWrapper.factory() == factory);
    }

    function testSetFactoryAfterFactoryIsSet() public {
        testSetFactoryShouldPass();
        vm.expectRevert();
        testSetFactoryShouldPass();

        assertTrue(yardNFTWrapper.factory() == factory);
    }
}