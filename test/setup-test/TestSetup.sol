// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract TestSetup is Test {
    modifier isSetUp(address _address) {
        assertFalse(_address == address(0));
        _;
    }
}