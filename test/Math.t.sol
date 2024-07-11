// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Math} from "../src/contracts/libraries/Math.sol";

contract MathTest is Test {
    uint256[] internal testArray;

    function setUp() public {}

    function testSetUp() public {}

    function testRandom(uint256 i) public {
        vm.assume(i != 0);
        uint256 rand = Math.random(i);
        assertFalse(rand == i);
    }

    function testPopArray() public {
        for (uint i; i < 10; i++) {
            testArray.push(i + 1);
        }

        uint256 j = (block.timestamp) % (testArray.length);
        uint256 testArrayLength = testArray.length;
        testArray = Math.popArray(testArray, j);
        assertTrue(testArray.length == testArrayLength - 1);
    }
}