// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

/**
* @title IYardToken
* @author fps (@0xfps).
* @dev Interface for interacting with the Yard ERC-20 Token.
* @notice The YardToken is minted to specific addresses set by the factory.
*/

interface IYardToken {
    function mint(address to) external;
    function burn(uint256 amount) external;
}