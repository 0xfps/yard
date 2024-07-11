// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./YardFee.t.sol";

contract GetFeeTest is YardFeeTest {
    function testAfterDeployment() public {
        assertTrue(yardFee.getFee() == fee);
    }

    function testGetFeeAfterQueue() public {
        vm.prank(owner);
        yardFee.queueFeeChange(otherFee);

        assertTrue(yardFee.getFee() == fee);
    }

    function testGetFeeAfterQueueAndTimeNotPassed() public {
        vm.prank(owner);
        yardFee.queueFeeChange(otherFee);

        skip(5 days);

        assertTrue(yardFee.getFee() == fee);
    }

    function testGetFeeAfterQueueAndTimePassed() public {
        vm.prank(owner);
        yardFee.queueFeeChange(otherFee);

        skip(11 days);

        assertTrue(yardFee.getFee() == otherFee);
    }

    function testAfterDeleteFee() public {
        testGetFeeAfterQueueAndTimePassed();

        vm.prank(owner);
        yardFee.deleteFee();
        assertTrue(yardFee.getFee() == otherFee);
    }

    function testAfterDeleteFeeAndTimeNotPassed() public {
        testGetFeeAfterQueueAndTimePassed();

        vm.prank(owner);
        yardFee.deleteFee();
        skip(5 days);
        assertTrue(yardFee.getFee() == otherFee);
    }

    function testAfterDeleteFeeAndTimePassed() public {
        testGetFeeAfterQueueAndTimePassed();

        vm.prank(owner);
        yardFee.deleteFee();
        skip(11 days);
        assertTrue(yardFee.getFee() == fee);
    }
}