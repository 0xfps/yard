// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./YardFactory.t.sol";

contract YardFactorySetRouterTest is YardFactoryTest {
    function testSetRouterByNonOwner(address hackers) public {
        vm.assume((hackers != zero) && (hackers != owner));
        vm.prank(hackers);
        vm.expectRevert();
        yardFactory.setRouter(randomAddress);
    }

    function testSetRouterWithZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert();
        yardFactory.setRouter(zero);
    }

    function testSetRouterWithAnyAddress(address router) public {
        vm.assume(router != zero);
        vm.prank(owner);
        yardFactory.setRouter(router);

        assertTrue(yardFactory.ROUTER() == router);
        assertTrue(yardFactory.owner() == zero);
    }

    function testSetRouterWithProperRouterAddress() public {
        vm.prank(owner);
        yardFactory.setRouter(address(yardRouter));

        assertTrue(yardFactory.ROUTER() == address(yardRouter));
        assertTrue(yardFactory.owner() == zero);
    }
}