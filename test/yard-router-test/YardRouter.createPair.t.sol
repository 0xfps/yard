// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IYardFee } from "../../src/contracts/interfaces/IYardFee.sol";

import "./YardRouter.t.sol";

contract YardRouterCreatePairTest is YardRouterTest {
    function testCreatePairWithNFTAAsZeroAddress() public completeSetup {
        uint256[] memory ids = _getIDsFor(chris);

        vm.prank(chris);
        vm.expectRevert();
        yardRouter.createPair(
            IERC721(address(0)),
            ids,
            IERC721(testNFTB),
            ids,
            FIFTY_CENTS,
            dick
        );
    }

    function testCreatePairWithNFTBAsZeroAddress() public completeSetup {
        uint256[] memory ids = _getIDsFor(chris);

        vm.prank(chris);
        vm.expectRevert();
        yardRouter.createPair(
            IERC721(testNFTA),
            ids,
            IERC721(address(0)),
            ids,
            FIFTY_CENTS,
            dick
        );
    }

    function testCreatePairWithZeroLengthArray() public completeSetup {
        uint256[] memory fakeIds = new uint256[] (0);
        uint256[] memory ids = _getIDsFor(chris);

        vm.prank(chris);
        vm.expectRevert();
        yardRouter.createPair(
            IERC721(testNFTA),
            fakeIds,
            IERC721(testNFTB),
            ids,
            FIFTY_CENTS,
            dick
        );
    }

    function testCreatePairWithUnmatchedLengthArray() public completeSetup {
        uint256[] memory fakeIds = new uint256[] (1);
        fakeIds[0] = 17;
        uint256[] memory ids = _getIDsFor(chris);

        vm.prank(chris);
        vm.expectRevert();
        yardRouter.createPair(
            IERC721(testNFTA),
            fakeIds,
            IERC721(testNFTB),
            ids,
            FIFTY_CENTS,
            dick
        );
    }

    function testCreatePairWithToAsZeroAddress() public completeSetup {
        uint256[] memory ids = _getIDsFor(chris);

        vm.prank(chris);
        vm.expectRevert();
        yardRouter.createPair(
            IERC721(testNFTA),
            ids,
            IERC721(testNFTB),
            ids,
            FIFTY_CENTS,
            zero
        );
    }

    function testCreatePairWithUnsettableFee(uint256 fee) public completeSetup {
        vm.assume((fee > 0) && (fee != TEN_CENTS) && (fee != THIRTY_CENTS) && (fee != FIFTY_CENTS));
        uint256[] memory ids = _getIDsFor(chris);

        vm.prank(chris);
        vm.expectRevert();
        yardRouter.createPair(
            IERC721(testNFTA),
            ids,
            IERC721(testNFTB),
            ids,
            fee,
            dick
        );
    }

    function testCreateProperPair() public completeSetup {
        _createPair();

        uint256[] memory ids = _getIDsFor(chris);
        vm.prank(chris);
        yardRouter.createPair(
            IERC721(testNFTA),
            ids,
            IERC721(testNFTB),
            ids,
            FIFTY_CENTS,
            dick
        );
    }

    function testCreateProperPairWithZeroFee() public completeSetup {
        uint256[] memory ids = _getIDsFor(chris);
        vm.prank(chris);
        yardRouter.createPair(
            IERC721(testNFTA),
            ids,
            IERC721(testNFTB),
            ids,
            0,
            dick
        );

        assertTrue(YardPair(yardRouter.getPair(IERC721(testNFTA), IERC721(testNFTB))).getFee() == TEN_CENTS);
    }
}