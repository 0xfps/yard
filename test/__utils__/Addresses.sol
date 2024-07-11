// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

abstract contract Addresses is Test {
    address public owner = vm.addr(1);
    address public hacker = vm.addr(666);

    address public alice = vm.addr(0xa);
    address public bob = vm.addr(0xb);
    address public chris = vm.addr(0xc);
    address public dick = vm.addr(0xc);
    address public finn = vm.addr(0xf);
}