// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./YardRouter.t.sol";

contract YardRouterSwapNFTForExactNFTTest is YardRouterTest {
    function testSwapNFTForExactNFTWithPathNotEqualThanTwo() public completeSetup {
        _createPair();

        IERC721[] memory path = _getOnePath();

        vm.expectRevert();
        vm.prank(chris);

        yardRouter.swapNFTForExactNFT(
            path,
            16,
            2,
            chris
        );
    }

    function testSwapNFTForExactNFTWithInExistentPath() public completeSetup {
        _createPair();

        IERC721[] memory path = _getDirtyPath();

        vm.expectRevert();
        vm.prank(chris);

        yardRouter.swapNFTForExactNFT(
            path,
            16,
            2,
            chris
        );
    }

    function testSwapNFTForExactNFTToReceiverWithoutApproval(address receivers) public completeSetup {
        vm.assume((receivers.code.length == 0) && (receivers != zero));
        _createPair();

        IERC721[] memory path = _getTwoPaths();

        vm.expectRevert();
        vm.prank(chris);
        yardRouter.swapNFTForExactNFT(
            path,
            16,
            2,
            receivers
        );
    }

    function testSwapNFTForExactNFTToReceiver(address receivers) public completeSetup {
        vm.assume((receivers.code.length == 0) && (receivers != zero));

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
            receivers
        );

        assertTrue(path[1].ownerOf(idOut) == receivers);
    }
}