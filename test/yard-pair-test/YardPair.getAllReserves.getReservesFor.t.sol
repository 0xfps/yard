// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./YardPair.t.sol";

contract YardPairGetAllReservesGetReservesForTest is YardPairTest {
    uint256 internal nftID = 5;
    uint256 internal secondNFTID = 6;
    uint256 internal finnNFTID = 33;
    uint256 internal chrisNFTID = 19;
    uint256 internal wId;
    uint256 internal secondWId;

    modifier sendNFTFirst() {
        vm.prank(alice);
        testNFTA.safeTransferFrom(alice, address(yardPair), nftID);

        vm.prank(alice);
        testNFTA.safeTransferFrom(alice, address(yardPair), secondNFTID);

        vm.prank(chris);
        testNFTB.safeTransferFrom(chris, address(yardPair), chrisNFTID);

        vm.prank(finn);
        testNFTB.safeTransferFrom(finn, address(yardPair), finnNFTID);

        _;
    }

    modifier addLiquiditySecond() {
        vm.prank(address(yardRouter));
        wId = yardPair.addLiquidity(
            IERC721(testNFTA),
            nftID,
            alice,
            bob
        );

        vm.prank(address(yardRouter));
        yardPair.addLiquidity(
            IERC721(testNFTA),
            secondNFTID,
            alice,
            bob
        );

        vm.prank(address(yardRouter));
        secondWId = yardPair.addLiquidity(
            IERC721(testNFTB),
            chrisNFTID,
            chris,
            bob
        );

        _;
    }

    modifier skipTimeThird() {
        skip(31 days);

        _;
    }

    function testGetAllReservesBeforeLiquidityProvision() public {
        (uint256 reserveA, uint256 reserveB) = yardPair.getAllReserves();
        assertTrue(reserveA == 0);
        assertTrue(reserveB == 0);
    }

    function testGetAllReservesAfterLiquidityProvision() public sendNFTFirst addLiquiditySecond {
        (uint256 reserveA, uint256 reserveB) = yardPair.getAllReserves();
        assertTrue(reserveA != 0);
        assertTrue(reserveB != 0);
    }

    function testGetAllReservesAfterLiquidityProvisionAndRemoval() public sendNFTFirst addLiquiditySecond skipTimeThird {
        (uint256 reserveABefore, uint256 reserveBBefore) = yardPair.getAllReserves();
        assertTrue(reserveABefore != 0);
        assertTrue(reserveBBefore != 0);

        _removeSomeLiquidity();

        (uint256 reserveAAfter, uint256 reserveBAfter) = yardPair.getAllReserves();
        assertTrue(reserveAAfter != reserveABefore);
        assertTrue(reserveBAfter != reserveBBefore);
    }

    function testGetReservesForBeforeLiquidityProvision() public {
        (uint256 reserveA, uint256[] memory reserveAArr) = yardPair.getReservesFor(IERC721(testNFTA));
        (uint256 reserveB, uint256[] memory reserveBArr) = yardPair.getReservesFor(IERC721(testNFTB));

        assertTrue(reserveA == 0);
        assertTrue(reserveB == 0);

        assertTrue(reserveAArr.length == 0);
        assertTrue(reserveBArr.length == 0);
    }

    function testGetReservesForAfterLiquidityProvision() public sendNFTFirst addLiquiditySecond {
        (uint256 reserveA, uint256[] memory reserveAArr) = yardPair.getReservesFor(IERC721(testNFTA));
        (uint256 reserveB, uint256[] memory reserveBArr) = yardPair.getReservesFor(IERC721(testNFTB));

        assertTrue(reserveA != 0);
        assertTrue(reserveB != 0);

        assertTrue(reserveAArr.length != 0);
        assertTrue(reserveBArr.length != 0);
    }

    function testGetReservesForAfterLiquidityProvisionAndRemoval() public sendNFTFirst addLiquiditySecond skipTimeThird {
        (uint256 reserveABefore, uint256[] memory reserveABeforeArr) = yardPair.getReservesFor(IERC721(testNFTA));
        (uint256 reserveBBefore, uint256[] memory reserveBBeforeArr) = yardPair.getReservesFor(IERC721(testNFTB));

        assertTrue(reserveABefore != 0);
        assertTrue(reserveBBefore != 0);

        assertTrue(reserveABeforeArr.length != 0);
        assertTrue(reserveBBeforeArr.length != 0);

        _removeSomeLiquidity();

        (uint256 reserveAAfter, uint256[] memory reserveAAfterArr) = yardPair.getReservesFor(IERC721(testNFTA));
        (uint256 reserveBAfter, uint256[] memory reserveBAfterArr) = yardPair.getReservesFor(IERC721(testNFTB));

        assertTrue(reserveAAfter != reserveABefore);
        assertTrue(reserveBAfter != reserveBBefore);

        assertTrue(reserveAAfterArr.length != reserveABeforeArr.length);
        assertTrue(reserveBAfterArr.length != reserveBBeforeArr.length);
    }

    function _removeSomeLiquidity() internal {
        vm.prank(address(yardRouter));
        yardPair.removeLiquidity(
            IERC721(testNFTA),
            nftID,
            wId,
            alice,
            bob
        );

        vm.prank(address(yardRouter));
        yardPair.removeLiquidity(
            IERC721(testNFTB),
            chrisNFTID,
            secondWId,
            chris,
            bob
        );
    }
}