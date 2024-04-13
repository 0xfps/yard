// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
* @title IYardToken
* @author fps (@0xfps).
* @dev Interface for interacting with the Yard ERC-20 Token.
* @notice   The YardToken is minted to specific addresses set by the factory.
*           The `mint()` function is only callable by the `YardPair` contract.
*/

interface IYardToken {
    function mint() external;
    function burn(uint256 amount) external;
}