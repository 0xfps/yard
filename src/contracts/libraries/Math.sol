// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
* @title Math
* @author fps (@0xfps).
* @dev A simple, low-built, math library to generate random numbers within a limit.
*/

library Math {
    function random(uint256 limit) internal view returns (uint256) {
        return uint256(keccak256(abi.encode(block.timestamp))) % limit;
    }

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