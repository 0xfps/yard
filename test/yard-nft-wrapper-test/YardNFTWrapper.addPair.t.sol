// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./YardNFTWrapper.setFactory.t.sol";

contract YardNFTWrapperAddPairTest is YardNFTWrapperSetFactoryTest {
    function testAddPairByNonFactory(address adder) public {
        testSetFactoryShouldPass();

        vm.assume(adder != factory);
        vm.prank(adder);
        vm.expectRevert();
        yardNFTWrapper.addPair(pair);
    }

    function testAddPairByFactoryWithZeroAddress() public {
        testSetFactoryShouldPass();

        vm.prank(factory);
        vm.expectRevert();
        yardNFTWrapper.addPair(zero);
    }

    function testAddProperPairShouldPass() public {
        testSetFactoryShouldPass();

        vm.prank(factory);
        yardNFTWrapper.addPair(pair);
        assertTrue(yardNFTWrapper.allowedPairs(pair));
    }
}