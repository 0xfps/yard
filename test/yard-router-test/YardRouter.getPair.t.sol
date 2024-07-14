// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./YardRouter.t.sol";

contract YardRouterGetPairTest is YardRouterTest {
    address newPair;

    function testGetPairForInexistentPair(address nftA, address nftB) public completeSetup {
        vm.expectRevert();
        yardRouter.getPair(IERC721(nftA), IERC721(nftB));
    }

    function testGetPairForCreatedPair() public completeSetup {
        newPair = _createPair();
        assertTrue(yardRouter.getPair(IERC721(testNFTA), IERC721(testNFTB)) == newPair);
        assertTrue(yardRouter.getPair(IERC721(testNFTB), IERC721(testNFTA)) == newPair);
    }
}