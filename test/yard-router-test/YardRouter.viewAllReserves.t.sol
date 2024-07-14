// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./YardRouter.t.sol";

contract YardRouterViewAllReservesTest is YardRouterTest {
    function testViewAllReservesForInexistentPair(address nftA, address nftB) public completeSetup {
        vm.prank(alice);
        vm.expectRevert();
        yardRouter.viewAllReserves(IERC721(nftA), IERC721(nftB));
    }

    function testViewReservesForCreatedPair() public completeSetup {
        _createPair();

        (uint256 supplyA, uint256 supplyB) = yardRouter.viewAllReserves(IERC721(testNFTA), IERC721(testNFTB));
        assertTrue(supplyA == 5);
        assertTrue(supplyB == 5);
    }
}