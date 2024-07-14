// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./YardPair.t.sol";

contract YardPairCalculateRewardsTest is YardPairTest {
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

    function testCalculateRewardsForAllBeforeProvision(address providers) public {
        uint256 rewards = yardPair.calculateRewards(providers);
        assertTrue(rewards == 0);
    }

    function testCalculateRewardsAfterProvision() public sendNFTFirst addLiquiditySecond skipTimeThird sendSomeTokensFourth {
        uint256 rewardsAlice = yardPair.calculateRewards(alice);
        uint256 rewardsBob = yardPair.calculateRewards(bob);
        uint256 rewardsChris = yardPair.calculateRewards(chris);
        assertTrue(rewardsAlice >= 0);
        assertTrue(rewardsBob == 0);
        assertTrue(rewardsChris >= 0);
    }
}