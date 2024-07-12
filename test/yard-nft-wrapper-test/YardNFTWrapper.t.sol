// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../__utils__/Addresses.sol";
import { YardNFTWrapper } from "../../src/contracts/utils/YardNFTWrapper.sol";

contract YardNFTWrapperTest is Addresses {
    YardNFTWrapper public yardNFTWrapper;
    uint256 internal forkId;
    string internal name = "Wrapped Yard NFT";
    string internal symbol = "WyNFT";

    function setUp() public {
        /// I don't want to persist this contract on this fork.
        forkId = vm.createSelectFork(rpc);
        vm.prank(owner);
        yardNFTWrapper = new YardNFTWrapper();
    }

    function testSetup() public {
        assertTrue(keccak256(bytes(yardNFTWrapper.name())) == keccak256(bytes(name)));
        assertTrue(keccak256(bytes(yardNFTWrapper.symbol())) == keccak256(bytes(symbol)));
        assertTrue(yardNFTWrapper.factory() == address (0));
    }
}