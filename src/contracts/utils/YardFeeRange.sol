// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
* @title    YardFeeRange
* @author   fps (@0xfps).
* @dev      An abstract contract that controls the settable fees on Yard pools.
*/

abstract contract YardFeeRange {
    uint32 internal constant TEN_CENTS = 1e5;
    uint32 internal constant THIRTY_CENTS = 3e5;
    uint32 internal constant FIFTY_CENTS = 5e5;

    /// @dev    Return true if the fee to be set is equal to one of the defined three.
    /// @param  _fee    Fee value.
    /// @return bool    Settable status.
    function feeIsSettable(uint256 _fee) public pure returns (bool) {
        return (
            _fee == TEN_CENTS ||
            _fee == THIRTY_CENTS ||
            _fee == FIFTY_CENTS
        );
    }
}