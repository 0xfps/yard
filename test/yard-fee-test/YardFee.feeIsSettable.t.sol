// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./YardFee.t.sol";

contract GetFeeTest is YardFeeTest {
    function testFeeIsSettable() public {
        assertTrue(yardFee.feeIsSettable(TEN_CENTS));
        assertTrue(yardFee.feeIsSettable(THIRTY_CENTS));
        assertTrue(yardFee.feeIsSettable(FIFTY_CENTS));
    }

    function testFeeIsSettableExpectFail(uint256 _fee) public {
        vm.assume((_fee != TEN_CENTS) && (_fee != THIRTY_CENTS) && (_fee != FIFTY_CENTS));
        assertFalse(yardFee.feeIsSettable(_fee));
    }
}