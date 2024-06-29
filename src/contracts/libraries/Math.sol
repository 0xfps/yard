// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
* @title    Math
* @author   fps (@0xfps).
* @dev      A simple, low-built, math library to generate random numbers within a limit.
*/

library Math {
    /// @dev    Return a random number between 0 and `limit`.
    /// @param  limit   Upper limit of random number, not included.
    /// @return uint256 Random number between 0 and `limit`.
    function random(uint256 limit) internal view returns (uint256) {
        return uint256(
            keccak256(
                abi.encode(
                    block.timestamp,
                    block.number,
                    uint256(blockhash(block.number))
                )
            )
        ) % limit;
    }

    /// @dev    Remove element in index `index` from `array`.
    /// @param  array       Array.
    /// @param  index       Index of element to be removed.
    /// @return uint256[]   Updated storage array.
    function popArray(uint256[] storage array, uint256 index)
        internal
        returns (uint256[] storage)
    {
        uint256 len = array.length;
        array[index] = array[len - 1];
        array.pop();
        return array;
    }
}