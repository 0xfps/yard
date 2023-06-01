// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

/**
* @title Math
* @author fps (@0xfps).
* @dev A math library to generate random numbers within a limit.
*/

library Math {
    function random(uint256 limit) internal view returns (uint256) {
        return uint256(keccak256(abi.encode(block.timestamp))) % limit;
    }
}