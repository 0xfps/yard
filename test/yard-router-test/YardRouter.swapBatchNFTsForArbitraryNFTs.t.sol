// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./YardRouter.t.sol";

contract YardRouterSwapBatchNFTsForArbitraryNFTsTest is YardRouterTest {
    function testSwapBatchNFTsForArbitraryNFTsWithPathNotEqualToTwo() public completeSetup {
        _createPair();

        uint256[] memory idsIn = _getIDsFor(chris);
        IERC721[] memory path = _getOnePath();

        vm.prank(chris);
        vm.expectRevert();
        yardRouter.swapBatchNFTsForArbitraryNFTs(
            path,
            idsIn,
            dick
        );
    }

    function testSwapBatchNFTsForArbitraryNFTsWithLengthMismatch() public completeSetup {
        _createPair();

        uint256[] memory idsIn = new uint256[] (0);
        IERC721[] memory path = _getTwoPaths();

        vm.prank(chris);
        vm.expectRevert();
        yardRouter.swapBatchNFTsForArbitraryNFTs(
            path,
            idsIn,
            dick
        );
    }

    function testSwapBatchNFTsForArbitraryNFTsProperly(address receivers) public completeSetup {
        vm.assume((receivers.code.length == 0) && (receivers != zero));
        _createPair();
        _mintTokens();

        uint256[] memory idsIn = _getIDsFor(chris);
        IERC721[] memory path = _getTwoPaths();

        vm.prank(chris);
        uint256[] memory arbitraryIds = yardRouter.swapBatchNFTsForArbitraryNFTs(
            path,
            idsIn,
            receivers
        );

        for (uint256 i; i < arbitraryIds.length; i++) {
            assertTrue(path[1].ownerOf(arbitraryIds[i]) == address(receivers));
        }
    }
}