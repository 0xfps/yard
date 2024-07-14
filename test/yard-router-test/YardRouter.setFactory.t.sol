// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./YardRouter.t.sol";

contract YardRouterSetFactoryTest is YardRouterTest {
    function testSetFactoryByNonOwner(address hackers) public {
        vm.assume(hackers != owner);
        vm.expectRevert();
        vm.prank(hackers);
        yardRouter.setFactory(address(yardFactory));
    }

    function testSetFactoryWithZeroAddress() public {
        vm.expectRevert();
        vm.prank(owner);
        yardRouter.setFactory(zero);
    }

    function testSetFactoryProperly() public {
        vm.prank(owner);
        yardRouter.setFactory(address(yardFactory));

        assertTrue(yardRouter.owner() == zero);
    }
}