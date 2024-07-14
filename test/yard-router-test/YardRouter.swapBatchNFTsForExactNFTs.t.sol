// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./YardRouter.t.sol";

contract YardRouterSwapBatchNFTsForExactNFTsTest is YardRouterTest {
    function testSwapBatchNFTsForExactNFTsWithPathNotEqualToTwo() public completeSetup {
        _createPair();

        uint256[] memory idsOut = _getIDsFor(alice);
        uint256[] memory idsIn = _getIDsFor(chris);
        IERC721[] memory path = _getOnePath();

        vm.prank(chris);
        vm.expectRevert();
        yardRouter.swapBatchNFTsForExactNFTs(
            path,
            idsIn,
            idsOut,
            dick
        );
    }

    function testSwapBatchNFTsForExactNFTsWithMismatchedPath() public completeSetup {
        _createPair();

        uint256[] memory idsOut = _getIDsFor(alice);
        uint256[] memory idsIn = new uint256[] (0);
        IERC721[] memory path = _getTwoPaths();

        vm.prank(chris);
        vm.expectRevert();
        yardRouter.swapBatchNFTsForExactNFTs(
            path,
            idsIn,
            idsOut,
            dick
        );
    }

    function testSwapBatchNFTsForExactNFTsWithMismatchedLength() public completeSetup {
        _createPair();

        uint256[] memory idsOut = _getIDsFor(alice);
        uint256[] memory idsIn = new uint256[] (1);
        idsIn[0] = 17;
        IERC721[] memory path = _getTwoPaths();

        vm.prank(chris);
        vm.expectRevert();
        yardRouter.swapBatchNFTsForExactNFTs(
            path,
            idsIn,
            idsOut,
            dick
        );
    }

    function testSwapBatchNFTsForExactNFTsProperly(address receivers) public completeSetup {
        vm.assume((receivers.code.length == 0) && (receivers != zero));
        _createPair();
        _mintTokens();

        uint256[] memory idsOut = _getIDsFor(alice);
        uint256[] memory idsIn = _getIDsFor(chris);
        IERC721[] memory path = _getTwoPaths();

        vm.prank(chris);
        yardRouter.swapBatchNFTsForExactNFTs(
            path,
            idsIn,
            idsOut,
            receivers
        );
    }
}