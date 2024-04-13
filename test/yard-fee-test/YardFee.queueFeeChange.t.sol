// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./YardFee.t.sol";

contract QueueFeeChangeTest is YardFeeTest {
    function testQueueByNonOwner(uint256 amount) public {
        vm.expectRevert();
        vm.prank(hacker);
        yardFee.queueFeeChange(amount);
    }

    function testQueueFeeWhenInProgressAndLockNotPassed(uint256 amount) public {
        vm.assume(amount < type(uint256).max - 2);
        vm.prank(owner);
        yardFee.queueFeeChange(amount);

        skip(3 days);

        vm.expectRevert();
        vm.prank(owner);
        yardFee.queueFeeChange(amount * 2);
    }

    function testQueueFeeWhenInProgressAndLockPassed(uint256 amount) public {
        vm.assume(amount < type(uint256).max - 2);
        vm.prank(owner);
        yardFee.queueFeeChange(amount);

        skip(8 days);

        vm.prank(owner);
        yardFee.queueFeeChange(amount + 2);

        assertEq(yardFee.getFee(), amount);

        skip(7 days);

        assertEq(yardFee.getFee(), amount + 2);
    }
}