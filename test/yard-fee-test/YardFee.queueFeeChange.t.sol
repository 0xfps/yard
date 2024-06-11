// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./YardFee.t.sol";

contract QueueFeeChangeTest is YardFeeTest {
    uint32 internal constant TEN_CENTS = 1e5;
    uint32 internal constant THIRTY_CENTS = 3e5;
    uint32 internal constant FIFTY_CENTS = 5e5;

    function testQueueByNonOwner(uint256 amount) public {
        vm.expectRevert();
        vm.prank(hacker);
        yardFee.queueFeeChange(amount);
    }

    function testQueueFeeWhenInProgressAndLockNotPassed() public {
        vm.prank(owner);
        yardFee.queueFeeChange(FIFTY_CENTS);

        skip(3 days);

        vm.expectRevert();
        vm.prank(owner);
        yardFee.queueFeeChange(THIRTY_CENTS);
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

    function feeIsSettable(uint256 _fee) public pure returns (bool) {
        return (
            _fee == TEN_CENTS ||
            _fee == THIRTY_CENTS ||
            _fee == FIFTY_CENTS
        );
    }
}