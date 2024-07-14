// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./YardPair.t.sol";

contract YardPairRemoveLiquidityTest is YardPairTest, IERC721Receiver {
    uint256 internal nftID = 5;
    uint256 internal finnNFTID = 33;
    uint256 internal wId;

    modifier sendNFTFirst() {
        vm.prank(alice);
        testNFTA.safeTransferFrom(alice, address(yardPair), nftID);

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

        _;
    }

    modifier skipTimeThird() {
        skip(31 days);

        _;
    }

    function testRemoveLiquidityWithCallFromNonRouter(address hackers) public sendNFTFirst addLiquiditySecond {
        vm.assume(hackers != address(yardRouter));
        vm.prank(hackers);
        vm.expectRevert();
        yardPair.removeLiquidity(
            IERC721(testNFTA),
            nftID,
            wId,
            alice,
            bob
        );
    }

    function testRemoveLiquidityWithNFTNotEitherNFTAOrNFTB(address nft) public sendNFTFirst addLiquiditySecond {
        vm.assume((nft != address(testNFTA)) && (nft != address(testNFTB)));
        vm.prank(address(yardRouter));
        vm.expectRevert();
        yardPair.removeLiquidity(
            IERC721(nft),
            nftID,
            wId,
            alice,
            bob
        );
    }

    function testRemoveLiquidityWithPeriodNotPastLiquidityPeriod(uint256 time) public sendNFTFirst addLiquiditySecond {
        vm.assume(time < (block.timestamp + 30 days));
        vm.prank(address(yardRouter));
        vm.expectRevert();
        yardPair.removeLiquidity(
            IERC721(testNFTA),
            nftID,
            wId,
            alice,
            bob
        );
    }

    function testRemoveLiquidityWhenNFTToBeRemovedWasNotProvidedByFrom(address hackers) public sendNFTFirst addLiquiditySecond skipTimeThird {
        vm.assume(hackers != alice);
        vm.prank(address(yardRouter));
        vm.expectRevert();
        yardPair.removeLiquidity(
            IERC721(testNFTA),
            nftID,
            wId,
            hackers,
            bob
        );
    }
    
    function testRemoveLiquidityWithAMismatchedWrappedToken(uint256 wrappedId) public sendNFTFirst addLiquiditySecond skipTimeThird {
        vm.assume(wrappedId != wId);
        vm.prank(address(yardRouter));
        vm.expectRevert();
        yardPair.removeLiquidity(
            IERC721(testNFTA),
            nftID,
            wrappedId,
            alice,
            bob
        );
    }

    /// Line 222 in YardPair.sol is unreachable and hence untestable, technically, but should be left there.

    function testRemoveLiquidityWithToAsZeroAddress() public sendNFTFirst addLiquiditySecond skipTimeThird {
        vm.prank(address(yardRouter));
        vm.expectRevert();
        yardPair.removeLiquidity(
            IERC721(testNFTA),
            nftID,
            wId,
            alice,
            zero
        );
    }

    function testRemoveLiquidityForReleasedWID() public sendNFTFirst addLiquiditySecond skipTimeThird {
        vm.prank(address(yardPair));
        yardNFTWrapper.release(wId);

        vm.prank(address(yardRouter));
        vm.expectRevert();

        yardPair.removeLiquidity(
            IERC721(testNFTA),
            nftID,
            wId,
            alice,
            bob
        );
    }

    function testRemoveLiquidityForNFTStillInPool(address receivers) public sendNFTFirst addLiquiditySecond skipTimeThird {
        vm.assume((receivers != zero) && (receivers.code.length == 0));
        assertTrue(IERC721(testNFTA).ownerOf(nftID) == address(yardPair));

        vm.prank(address(yardRouter));
        uint256 idOut = yardPair.removeLiquidity(
            IERC721(testNFTA),
            nftID,
            wId,
            alice,
            receivers
        );

        assertTrue(idOut == nftID);
        assertTrue(IERC721(testNFTA).ownerOf(nftID) == receivers);

        (uint256 aSupply, uint256 bSupply) = yardPair.getAllReserves();
        (uint256 supplyA, uint256[] memory supplyAArr) = yardPair.getReservesFor(IERC721(testNFTA));

        /// One was added and one was removed, all is supposed to be 0.
        assertTrue((aSupply == 0) && (bSupply == 0));

        assertTrue(supplyA == 0);
        assertTrue(supplyAArr.length == 0);
    }

    function testRemoveLiquidityForNFTSwappedOutOfPool() public sendNFTFirst addLiquiditySecond skipTimeThird {
        assertTrue(IERC721(testNFTA).ownerOf(nftID) == address(yardPair));
        assertTrue(IERC721(testNFTB).ownerOf(finnNFTID) == finn);

        vm.prank(finn);
        testNFTB.safeTransferFrom(finn, address(yardPair), finnNFTID);

        vm.prank(address(yardRouter));
        yardPair.swap(
            IERC721(testNFTB),
            finnNFTID,
            IERC721(testNFTA),
            nftID,
            finn
        );

        assertTrue(IERC721(testNFTA).ownerOf(nftID) == finn);

        vm.prank(address(yardRouter));
        uint256 idOut = yardPair.removeLiquidity(
            IERC721(testNFTA),
            nftID,
            wId,
            alice,
            bob
        );

        assertTrue(idOut == nftID);
        assertTrue(yardNFTWrapper.isReleased(wId));

        (uint256 aSupply, uint256 bSupply) = yardPair.getAllReserves();
        (uint256 supplyA, uint256[] memory supplyAArr) = yardPair.getReservesFor(IERC721(testNFTA));
        (uint256 supplyB, uint256[] memory supplyBArr) = yardPair.getReservesFor(IERC721(testNFTB));

        assertTrue((aSupply == 0) || (bSupply == 0));
        assertTrue((aSupply == 1) || (bSupply == 1));

        assertTrue(supplyA == 0);
        assertTrue(supplyAArr.length == 0);

        assertTrue(supplyB == 1);
        assertTrue(supplyBArr.length == 1);
    }

    function testRemoveLiquidityReentrancy() public sendNFTFirst addLiquiditySecond skipTimeThird {
        vm.prank(address(yardRouter));
        yardPair.removeLiquidity(
            IERC721(testNFTA),
            nftID,
            wId,
            alice,
            address(this)
        );
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public returns (bytes4) {
        vm.prank(address(yardRouter));
        vm.expectRevert();
        yardPair.removeLiquidity(
            IERC721(testNFTA),
            nftID,
            wId,
            alice,
            address(this)
        );

        return IERC721Receiver.onERC721Received.selector;
    }
}