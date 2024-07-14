// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./YardRouter.t.sol";

contract YardRouterPrecalculateOutputNFTTest is YardRouterTest {
    function testPrecalculateOutputNFTForInExistentPair(address nftA, address nftB) public completeSetup {
        vm.assume(nftA != nftB);
        vm.prank(alice);
        vm.expectRevert();
        yardRouter.precalculateOutputNFT(IERC721(nftA), IERC721(nftB), IERC721(nftA));
    }

    function testPrecalculateOutputNFTForPairWithoutLiquidity() public completeSetup {
        _createPair();

        _skipTime();

        uint256[] memory ids = _getIDsFor(alice);
        uint256[] memory wIds = new uint256[] (5);
        wIds[0] = 0;
        wIds[1] = 2;
        wIds[2] = 4;
        wIds[3] = 6;
        wIds[4] = 8;

        uint256[] memory wIdsB = new uint256[] (5);
        wIdsB[0] = 1;
        wIdsB[1] = 3;
        wIdsB[2] = 5;
        wIdsB[3] = 7;
        wIdsB[4] = 9;

        vm.prank(alice);
        yardRouter.removeBatchLiquidity(
            IERC721(testNFTA),
            IERC721(testNFTB),
            IERC721(testNFTA),
            ids,
            wIds,
            alice
        );

        vm.prank(alice);
        yardRouter.removeBatchLiquidity(
            IERC721(testNFTA),
            IERC721(testNFTB),
            IERC721(testNFTB),
            ids,
            wIdsB,
            alice
        );

        vm.prank(alice);
        vm.expectRevert();
        yardRouter.precalculateOutputNFT(IERC721(testNFTA), IERC721(testNFTB), IERC721(testNFTA));
    }

    function testPrecalculateOutputNFT() public completeSetup {
        _createPair();
        vm.prank(alice);
        yardRouter.precalculateOutputNFT(IERC721(testNFTA), IERC721(testNFTB), IERC721(testNFTA));
    }
}