// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./YardFee.t.sol";

contract DeleteFeeTest is YardFeeTest {
    function setFee() public {
        vm.prank(owner);
        yardFee.queueFeeChange(fee);
    }

    function testDeleteByNonOwner() public {
        setFee();

        vm.prank(hacker);
        vm.expectRevert();
        yardFee.deleteFee();
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
}