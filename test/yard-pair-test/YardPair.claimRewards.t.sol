// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./YardPair.t.sol";

contract YardPairClaimRewardsTest is YardPairTest {
    uint256 internal nftID = 5;
    uint256 internal secondNFTID = 6;
    uint256 internal finnNFTID = 33;
    uint256 internal chrisNFTID = 19;
    uint256 internal wId;
    uint256 internal secondWId;

    modifier sendNFTFirst() {
        vm.prank(alice);
        testNFTA.safeTransferFrom(alice, address(yardPair), nftID);

        vm.prank(alice);
        testNFTA.safeTransferFrom(alice, address(yardPair), secondNFTID);

        vm.prank(chris);
        testNFTB.safeTransferFrom(chris, address(yardPair), chrisNFTID);

        vm.prank(finn);
        testNFTB.safeTransferFrom(finn, address(yardPair), finnNFTID);

        _;
    }

    modifier addLiquiditySecond() {
        vm.prank(address(yardRouter));
        wId = yardPair.addLiquidity(
            IERC721(testNFTA),
            nftID,
            alice,
            bob
        );

        vm.prank(address(yardRouter));
        secondWId = yardPair.addLiquidity(
            IERC721(testNFTA),
            secondNFTID,
            alice,
            bob
        );

        vm.prank(address(yardRouter));
        yardPair.addLiquidity(
            IERC721(testNFTB),
            chrisNFTID,
            chris,
            bob
        );

        _;
    }

    modifier skipTimeThird() {
        skip(31 days);

        _;
    }

    modifier sendSomeTokensFourth() {
        vm.prank(finn);
        feeToken.transfer(address(yardPair), 100e6);

        _;
    }

    function testClaimRewardsForZeroAddress() public {
        vm.prank(address(yardRouter));
        vm.expectRevert();
        yardPair.claimRewards(zero);
    }

    function testClaimRewardsForLPWithZeroProvisions(address providers) public {
        vm.assume(providers != zero);
        vm.expectRevert();
        yardPair.claimRewards(providers);
    }

    function testClaimRewardsBeforeLiquidityPeriodIsOver() public sendNFTFirst addLiquiditySecond {
        vm.expectRevert();
        yardPair.claimRewards(alice);
    }

    function testClaimRewardsForProvider() public sendNFTFirst addLiquiditySecond skipTimeThird sendSomeTokensFourth {
        uint256 balanceBefore = feeToken.balanceOf(alice);
        uint256 prevTotalAmountClaimed = yardPair.totalAmountClaimed();

        yardPair.claimRewards(alice);
        yardPair.claimRewards(chris);

        uint256 balanceAfterAlice = feeToken.balanceOf(alice);
        uint256 balanceAfterChris = feeToken.balanceOf(chris);

        assertTrue(balanceAfterAlice >= balanceBefore);
        assertTrue(balanceAfterChris != 0);
        assertTrue(yardPair.totalAmountClaimed() >= prevTotalAmountClaimed);
    }

//    function testCalculateRewardsForAllBeforeProvision(address providers) public {
//        uint256 rewards = yardPair.calculateRewards(providers);
//        assertTrue(rewards == 0);
//    }
//
//    function
}