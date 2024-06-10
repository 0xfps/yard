// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import {YardFee} from "../../src/contracts/utils/YardFee.sol";

contract YardFeeTest is Test {
    YardFee public yardFee;
    address public owner = vm.addr(1);
    address public hacker = vm.addr(2);
    uint256 internal fee = 3 ether;

    function setUp() public {
        vm.prank(owner);
        yardFee = new YardFee(owner, 0);
    }

    function testSetUp() public {
        assertFalse(address(yardFee) == address(0));
    }
}
