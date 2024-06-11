// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./YardFee.t.sol";

contract GetFeeTest is YardFeeTest {
    function testAfterDeployment() public {
        assertTrue(yardFee.getFee() == 1e5);
    }

    function testWhenQueueInProgressAfterDeploy() public {
        vm.prank(owner);
        yardFee.queueFeeChange(fee);

        assertTrue(yardFee.getFee() == 1e5);
    }

    function testAfterQueueChange() public {
        vm.prank(owner);
        yardFee.queueFeeChange(fee);

        skip(11 days);

        assertTrue(yardFee.getFee() == fee);
    }

    function testWhenQueueInProgressAfterChange() public {
        vm.prank(owner);
        yardFee.queueFeeChange(fee);

        skip(11 days);

        assertTrue(yardFee.getFee() == fee);

        vm.prank(owner);
        yardFee.queueFeeChange(5e5);

        skip(6 days);

        assertTrue(yardFee.getFee() == fee);
    }

    function testWhenDeleteFee() public {
        testAfterQueueChange();

        vm.prank(owner);
        yardFee.deleteFee();

        skip(6 days);

        assertTrue(yardFee.getFee() == fee);
    }

    function testWhenDeleteFeeUpdated() public {
        testWhenDeleteFee();

        skip(2 days);

        assertTrue(yardFee.getFee() == 1e5);
    }
}