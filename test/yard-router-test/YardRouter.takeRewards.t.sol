// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./YardRouter.t.sol";

contract YardRouterTakeRewardsTest is YardRouterTest {
    function _swap() public completeSetup {
        _createPair();
        _mintTokens();

        uint256 idIn = 16;
        uint256 idOut = 2;
        IERC721[] memory path = _getTwoPaths();

        vm.prank(chris);
        yardRouter.swapNFTForExactNFT(
            path,
            idIn,
            idOut,
            dick
        );
    }

    function testTakeRewardsForInExistentPair(address nftA, address nftB) public completeSetup {
        vm.prank(alice);
        vm.expectRevert();
        yardRouter.takeRewards(IERC721(nftA), IERC721(nftB));
    }

    function testTakeRewardsAfterSwap() public {
        _swap();
        _skipTime();

        uint256 balanceBefore = feeToken.balanceOf(alice);

        vm.prank(alice);
        yardRouter.takeRewards(IERC721(testNFTA), IERC721(testNFTB));

        assertTrue(feeToken.balanceOf(alice) >= balanceBefore);
    }
}