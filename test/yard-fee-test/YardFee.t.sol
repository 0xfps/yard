// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {YardFee} from "../../src/contracts/utils/YardFee.sol";

contract YardFeeTest is Test {
    YardFee public yardFee;
    address public owner = vm.addr(1);
    address public hacker = vm.addr(2);
    address public newOwner = vm.addr(3);

    uint256 internal fee = 1e5;
    uint256 internal otherFee = 3e5;

    uint32 internal constant TEN_CENTS = 1e5;
    uint32 internal constant THIRTY_CENTS = 3e5;
    uint32 internal constant FIFTY_CENTS = 5e5;

    function setUp() public {
        vm.prank(owner);
        yardFee = new YardFee(owner, fee);
        assertTrue(yardFee.owner() == owner);
        assertTrue(yardFee.getFee() == fee);
    }

    /**
    * Foundry claims that the tests for YardFee covers 93.33% of statements and
    * 83.33% of branches. Because line 89 of the YardFee in the `_updateFee()`
    * function is not tested. However, the only way to test that line is by deploying
    * with an invalid fee, which this test below tests for and passes.
    *
    * `queueFeeChange()` cannot queue an un-settable fee which catches this early allowing
    * `_updateFee()` to pass the checks when updating a fee set by `queueFeeChange()`.
    */
    function testWrongSetup(uint256 _fee) public {
        vm.assume((_fee != TEN_CENTS) && (_fee != THIRTY_CENTS) && (_fee != FIFTY_CENTS));
        vm.prank(owner);
        vm.expectRevert();
        yardFee = new YardFee(owner, _fee);
    }

    function testProperSetup() public {
        vm.prank(owner);
        yardFee = new YardFee(owner, otherFee);
    }

    function testSetUp() public {
        assertFalse(address(yardFee) == address(0));
        assertTrue(yardFee.owner() == owner);
        assertTrue(yardFee.getFee() == fee);
    }
}
