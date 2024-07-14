// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./YardRouter.t.sol";

contract YardRouterRemoveLiquidityTest is IERC721Receiver, YardRouterTest {
    // Creation of pair has been handled by `testAddProperLiquiditySendToReceiver`.
    function testRemoveLiquidityAndSendToReceiver(address receivers) public completeSetup {
        vm.assume((receivers.code.length == 0) && (receivers != zero));
        _createPair();

        uint8 idAdded = 16;
        vm.prank(chris);
        uint256 wId = yardRouter.addLiquidity(
            IERC721(testNFTA),
            IERC721(testNFTB),
            IERC721(testNFTA),
            idAdded,
            receivers
        );

        _skipTime();

        assertTrue(testNFTA.ownerOf(idAdded) == address(yardRouter.getPair(IERC721(testNFTA), IERC721(testNFTB))));
        assertTrue(yardNFTWrapper.ownerOf(wId) == receivers);

        vm.prank(chris);
        uint256 idOut = yardRouter.removeLiquidity(
            IERC721(testNFTA),
            IERC721(testNFTB),
            IERC721(testNFTA),
            idAdded,
            wId,
            receivers
        );

        assertTrue(idOut == idAdded);
        assertTrue(testNFTA.ownerOf(idOut) == receivers);
    }

    function testRemoveLiquidityReentrancy() public completeSetup {
        _createPair();

        uint8 idAdded = 16;
        vm.prank(chris);
        uint256 wId = yardRouter.addLiquidity(
            IERC721(testNFTA),
            IERC721(testNFTB),
            IERC721(testNFTA),
            idAdded,
            address(this)
        );

        _skipTime();

        assertTrue(testNFTA.ownerOf(idAdded) == address(yardRouter.getPair(IERC721(testNFTA), IERC721(testNFTB))));

        vm.prank(chris);
        uint256 idOut = yardRouter.removeLiquidity(
            IERC721(testNFTA),
            IERC721(testNFTB),
            IERC721(testNFTA),
            idAdded,
            wId,
            address(this)
        );

        assertTrue(idOut == idAdded);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public returns (bytes4) {
        vm.prank(chris);
        vm.expectRevert();
        yardRouter.removeLiquidity(
            IERC721(testNFTA),
            IERC721(testNFTB),
            IERC721(testNFTA),
            16,
            4,
            chris
        );

        return IERC721Receiver.onERC721Received.selector;
    }
}