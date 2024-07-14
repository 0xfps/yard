// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./YardRouter.t.sol";

contract YardRouterSwapNFTForArbitraryNFTTest is YardRouterTest {
    function testSwapNFTForArbitraryNFTWithPathNotEqualToTwo() public completeSetup {
        _createPair();

        uint256 idIn = 17;
        IERC721[] memory path = _getOnePath();

        vm.prank(chris);
        vm.expectRevert();
        yardRouter.swapNFTForArbitraryNFT(
            path,
            idIn,
            dick
        );
    }

    function testSwapNFTForArbitraryNFTProperly(address receivers) public completeSetup {
        vm.assume((receivers.code.length == 0) && (receivers != zero));
        _createPair();
        _mintTokens();

        uint256 idIn = 17;
        IERC721[] memory path = _getTwoPaths();

        vm.prank(chris);
        uint256 arbitraryId = yardRouter.swapNFTForArbitraryNFT(
            path,
            idIn,
            receivers
        );

        assertTrue(testNFTB.ownerOf(arbitraryId) == address(receivers));
    }
}