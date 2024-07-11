// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./YardFee.t.sol";

contract DeleteFeeTest is YardFeeTest {
    function setFee() public {
        vm.prank(owner);
        yardFee.queueFeeChange(FIFTY_CENTS);
    }

    function testDeleteByNonOwner() public {
        setFee();

        vm.prank(hacker);
        vm.expectRevert();
        yardFee.deleteFee();
    }

    function testDeleteByOwner() public {
        setFee();

        skip(11 days);

        vm.prank(owner);
        yardFee.deleteFee();

        skip(11 days);
        assertTrue(yardFee.getFee() == fee);
    }

    function testDeleteFeeWhenNotInProgress() public {
        vm.prank(owner);
        yardFee.deleteFee();
    }

    function testDeleteFeeWhenInProgressAndLockNotPassed() public {
        vm.prank(owner);
        yardFee.queueFeeChange(FIFTY_CENTS);

        skip(3 days);

        vm.expectRevert();
        vm.prank(owner);
        yardFee.deleteFee();
    }

    function testDeleteFeeWhenInProgressAndLockPassed() public {
        vm.prank(owner);
        yardFee.queueFeeChange(TEN_CENTS);

        skip(8 days);

        vm.prank(owner);
        yardFee.deleteFee();

        assertEq(yardFee.getFee(), TEN_CENTS);

        skip(7 days);

        assertEq(yardFee.getFee(), fee);
    }

    function testDeleteByOwnerWhenInProgress() public {
        setFee();

        skip(4 days);

        vm.expectRevert();
        vm.prank(owner);
        yardFee.deleteFee();
    }

    function testDeleteByOwnerWhenNotInProgress() public {
        setFee();

        skip(7 days);

        vm.prank(owner);
        yardFee.deleteFee();
    }

    function testFeeChangedAfterDelete() public {
        testDeleteByOwnerWhenNotInProgress();
        skip(7 days);
        assertEq(yardFee.getFee(), 1e5);
    }

    function testDeleteFeeByNewOwner() public {
        vm.startPrank(owner);
        yardFee.queueFeeChange(3e5);
        skip(11 days);
        yardFee.transferOwnership(newOwner);
        vm.stopPrank();

        vm.startPrank(newOwner);
        yardFee.acceptOwnership();
        vm.stopPrank();

        vm.expectRevert();
        vm.prank(owner);

        yardFee.deleteFee();
    }

    function testDeleteByOwnerWhenInProgressAndLockNotPassed() public {
        vm.prank(owner);
        yardFee.queueFeeChange(FIFTY_CENTS);

        skip(3 days);

        vm.expectRevert();
        vm.prank(owner);
        yardFee.deleteFee();
    }

    function testDeleteByOwnerWhenNotInProgressAndTimePassed() public {
        vm.prank(owner);
        yardFee.deleteFee();

        skip(11 days);
        assertTrue(yardFee.getFee() == fee);
    }

    function testDeleteWhenInProgressAndLockPassed() public {
        vm.prank(owner);
        yardFee.queueFeeChange(TEN_CENTS);

        skip(8 days);

        vm.prank(owner);
        yardFee.deleteFee();

        assertEq(yardFee.getFee(), TEN_CENTS);

        skip(7 days);

        assertEq(yardFee.getFee(), fee);
    }
}