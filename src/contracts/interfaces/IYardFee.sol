// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
* @title    IYardFee
* @author   fps (@0xfps).
* @dev      Interface for the `YardFee` contract.
*/

interface IYardFee {
    /// @dev Return the set `YardPair` swap fee.
    function getFee() external returns (uint256);
}