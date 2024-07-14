// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./YardRouter.t.sol";

contract YardRouterRemoveBatchLiquidityTest is IERC721Receiver, YardRouterTest {
    // Creation of pair has been handled by `testAddProperLiquiditySendToReceiver`.
    function testRemoveBatchLiquidityWithZeroLengthArray() public completeSetup {
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

        _skipTime();

        uint256[] memory rmIds = new uint256[] (0);
        vm.prank(chris);
        vm.expectRevert();
        yardRouter.removeBatchLiquidity(
            IERC721(testNFTA),
            IERC721(testNFTB),
            IERC721(testNFTB),
            rmIds,
            wIds,
            dick
        );
    }

    function testRemoveBatchLiquidityWithUnmatchedLengthArrays() public completeSetup {
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

        _skipTime();

        uint256[] memory rmIds = new uint256[] (1);
        rmIds[0] = 16;

        vm.prank(chris);
        vm.expectRevert();
        yardRouter.removeBatchLiquidity(
            IERC721(testNFTA),
            IERC721(testNFTB),
            IERC721(testNFTB),
            rmIds,
            wIds,
            dick
        );
    }

    function testRemoveBatchLiquidityAndSendToReceivers(address receivers) public completeSetup {
        vm.assume((receivers.code.length == 0) && (receivers != zero));
        _createPair();

        uint256[] memory ids = _getIDsFor(chris);

        vm.prank(chris);
        uint256[] memory wIds = yardRouter.addBatchLiquidity(
            IERC721(testNFTA),
            IERC721(testNFTB),
            IERC721(testNFTB),
            ids,
            receivers
        );

        _skipTime();

        vm.prank(chris);
        yardRouter.removeBatchLiquidity(
            IERC721(testNFTA),
            IERC721(testNFTB),
            IERC721(testNFTB),
            ids,
            wIds,
            receivers
        );
    }

    function testRemoveBatchLiquidityReentrancy() public completeSetup {
        _createPair();

        uint256[] memory ids = _getIDsFor(chris);

        vm.prank(chris);
        uint256[] memory wIds = yardRouter.addBatchLiquidity(
            IERC721(testNFTA),
            IERC721(testNFTB),
            IERC721(testNFTB),
            ids,
            chris
        );

        _skipTime();

        vm.prank(chris);
        yardRouter.removeBatchLiquidity(
            IERC721(testNFTA),
            IERC721(testNFTB),
            IERC721(testNFTB),
            ids,
            wIds,
            address(this)
        );
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public returns (bytes4) {
        uint256[] memory ids = _getIDsFor(chris);
        uint256[] memory wIds = _getIDsFor(chris);

        vm.prank(chris);
        vm.expectRevert();
        yardRouter.removeBatchLiquidity(
            IERC721(testNFTA),
            IERC721(testNFTB),
            IERC721(testNFTB),
            ids,
            wIds,
            dick
        );

        return IERC721Receiver.onERC721Received.selector;
    }
}