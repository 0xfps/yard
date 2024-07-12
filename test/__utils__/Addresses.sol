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

    address public factory = vm.addr(uint256(bytes32(bytes("factory"))));
    address public pair = vm.addr(uint256(bytes32(bytes("pair"))));
    address public router = vm.addr(uint256(bytes32(bytes("router"))));

    address public zero = address(0);

    string public rpc = "https://ethereum-rpc.publicnode.com";

    address public cryptoPunks = 0x282BDD42f4eb70e7A9D9F40c8fEA0825B7f68C5D;
    uint256 public validId = 8000;
    uint256 public invalidID = 3305;
    uint256[] public validCryptoPunkIDs = [9721, 4701, 4806, 8437, 2242];
}