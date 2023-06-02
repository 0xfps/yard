// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import {Math} from "../src/contracts/libraries/Math.sol";

contract MathTest is Test {
    function setUp() public {}

    function testSetUp() public {}

    function testRandom(uint256 i) public {
        vm.assume(i != 0);
        uint256 rand = Math.random(i);
        assertFalse(rand == i);
    }
}