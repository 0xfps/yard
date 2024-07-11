// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./YardFee.t.sol";

contract QueueFeeChangeTest is YardFeeTest {
    function testQueueByNonOwner(uint256 amount) public {
        vm.expectRevert();
        vm.prank(hacker);
        yardFee.queueFeeChange(amount);
    }

    function testQueueFeeWhenNotInProgress() public {
        vm.prank(owner);
        yardFee.queueFeeChange(FIFTY_CENTS);
    }

    function testQueueUnsettableFeeWhenNotInProgress(uint256 _fee) public {
        vm.assume((_fee != TEN_CENTS) && (_fee != THIRTY_CENTS) && (_fee != FIFTY_CENTS));
        vm.expectRevert();
        vm.prank(owner);
        yardFee.queueFeeChange(_fee);
    }

    function testQueueFeeWhenInProgressAndLockNotPassed() public {
        vm.prank(owner);
        yardFee.queueFeeChange(FIFTY_CENTS);

        skip(3 days);

        vm.expectRevert();
        vm.prank(owner);
        yardFee.queueFeeChange(THIRTY_CENTS);
    }

    function testQueueUnsettableFeeWhenInProgressAndLockNotPassed(uint256 _fee) public {
        vm.assume((_fee != TEN_CENTS) && (_fee != THIRTY_CENTS) && (_fee != FIFTY_CENTS));
        vm.prank(owner);
        yardFee.queueFeeChange(FIFTY_CENTS);

        skip(3 days);

        vm.expectRevert();
        vm.prank(owner);
        yardFee.queueFeeChange(_fee);
    }

    function testQueueFeeWhenInProgressAndLockPassed() public {
        vm.prank(owner);
        yardFee.queueFeeChange(TEN_CENTS);

        skip(8 days);

        vm.prank(owner);
        yardFee.queueFeeChange(THIRTY_CENTS);

        assertEq(yardFee.getFee(), TEN_CENTS);

        skip(7 days);

        assertEq(yardFee.getFee(), THIRTY_CENTS);
    }

    function testQueueUnsettableFeeWhenInProgressAndLockPassed(uint256 _fee) public {
        vm.assume((_fee != TEN_CENTS) && (_fee != THIRTY_CENTS) && (_fee != FIFTY_CENTS));
        vm.prank(owner);
        yardFee.queueFeeChange(FIFTY_CENTS);

        skip(11 days);

        vm.expectRevert();
        vm.prank(owner);
        yardFee.queueFeeChange(_fee);

        assertTrue(yardFee.getFee() == FIFTY_CENTS);
    }
}