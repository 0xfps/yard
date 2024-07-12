// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./YardFactory.t.sol";

contract YardFactorySetWrapperTest is YardFactoryTest {
    function testSetWrapperByNonOwner(address hackers) public {
        vm.assume((hackers != zero) && (hackers != owner));
        vm.prank(hackers);
        vm.expectRevert();
        yardFactory.setWrapper(randomAddress);
    }

    function testSetWrapperWithZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert();
        yardFactory.setWrapper(zero);
    }

    function testSetWrapperWithAnyAddress(address wrapper) public {
        vm.assume(wrapper != zero);
        vm.prank(owner);
        yardFactory.setWrapper(wrapper);

        assertTrue(yardFactory.YARD_WRAPPER() == wrapper);
    }

    function testSetWrapperWithProperWrapperAddress() public {
        vm.prank(owner);
        yardFactory.setWrapper(address(yardNFTWrapper));

        assertTrue(yardFactory.YARD_WRAPPER() == address(yardNFTWrapper));
    }
}