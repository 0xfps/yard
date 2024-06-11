// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
* @title IYardFee
* @author fps (@0xfps).
* @dev Interface for `YardFee` contract.
*/

interface IYardFee {
    /// @dev Return set `YardPair` fee.
    function getFee() external returns (uint256);
}