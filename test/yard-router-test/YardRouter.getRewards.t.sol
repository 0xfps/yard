// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./YardRouter.t.sol";

contract YardRouterGetRewardsTest is YardRouterTest {
    function testGetRewardsForInexistentPair(address nftA, address nftB) public completeSetup {
        vm.prank(alice);
        vm.expectRevert();
        yardRouter.getRewards(IERC721(nftA), IERC721(nftB), finn);
    }

    function testGetRewardsForCreatedPair() public completeSetup {
        _createPair();

        uint256 reward = yardRouter.getRewards(IERC721(testNFTA), IERC721(testNFTB), alice);
        assertTrue(reward >= 0);
    }
}