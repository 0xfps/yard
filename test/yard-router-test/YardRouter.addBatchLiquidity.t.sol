// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./YardRouter.t.sol";

contract YardRouterAddBatchLiquidityTest is YardRouterTest {
    function testAddBatchLiquidityWithZeroLengthArray() public completeSetup {
        _createPair();

        uint256[] memory ids = new uint256[] (0);
        vm.prank(chris);
        vm.expectRevert();
        yardRouter.addBatchLiquidity(
            IERC721(testNFTA),
            IERC721(testNFTB),
            IERC721(testNFTA),
            ids,
            chris
        );
    }

    function testAddBatchLiquidityWithSpecifiedArray() public completeSetup {
        _createPair();

        uint256[] memory ids = _getIDsFor(chris);

        vm.prank(chris);
        uint256[] memory wIds = yardRouter.addBatchLiquidity(
            IERC721(testNFTA),
            IERC721(testNFTB),
            IERC721(testNFTB),
            ids,
            dick
        );

        assertTrue(wIds.length == ids.length);

        for (uint256 i; i < wIds.length; i++) {
            assertTrue(testNFTB.ownerOf(ids[i]) == address(yardRouter.getPair(IERC721(testNFTA), IERC721(testNFTB))));
            assertTrue(yardNFTWrapper.ownerOf(wIds[i]) == dick);
            assertFalse(yardNFTWrapper.isReleased(wIds[i]));
        }
    }
}