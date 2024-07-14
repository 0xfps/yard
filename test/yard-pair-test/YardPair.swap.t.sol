// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./YardPair.t.sol";

contract YardPairSwapTest is YardPairTest, IERC721Receiver {
    uint256 internal nftID = 5;
    uint256 internal secondNFTID = 6;
    uint256 internal finnNFTID = 33;
    uint256 internal wId;
    uint256 internal secondWId;

    modifier sendNFTFirst() {
        vm.prank(alice);
        testNFTA.safeTransferFrom(alice, address(yardPair), nftID);

        vm.prank(alice);
        testNFTA.safeTransferFrom(alice, address(yardPair), secondNFTID);

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
        secondWId = yardPair.addLiquidity(
            IERC721(testNFTA),
            secondNFTID,
            alice,
            bob
        );

        _;
    }

    modifier skipTimeThird() {
        skip(31 days);

        _;
    }

    function testSwapWithCallFromNonRouter(address hackers) public {
        vm.assume(hackers != address(yardRouter));
        vm.prank(hackers);
        vm.expectRevert();
        yardPair.swap(
            IERC721(testNFTB),
            finnNFTID,
            IERC721(testNFTA),
            nftID,
            finn
        );
    }

    function testSwapWithNFTsNotSentToPair(uint256 nftIds) public sendNFTFirst {
        vm.assume(nftIds != nftID);
        vm.prank(address(yardRouter));
        vm.expectRevert();
        yardPair.swap(
            IERC721(testNFTB),
            nftIds,
            IERC721(testNFTA),
            nftID,
            finn
        );
    }

    function testSwapWithNFTsWhenTheresZeroLiquidity() public sendNFTFirst {
        vm.prank(address(yardRouter));
        vm.expectRevert();
        yardPair.swap(
            IERC721(testNFTB),
            finnNFTID,
            IERC721(testNFTA),
            nftID,
            finn
        );
    }

    function testSwapForNFTThatHasBeenRemovedViaRemoveLiquidity() public sendNFTFirst addLiquiditySecond skipTimeThird {
        vm.prank(address(yardRouter));
        yardPair.removeLiquidity(
            IERC721(testNFTA),
            nftID,
            wId,
            alice,
            bob
        );

        vm.prank(address(yardRouter));
        vm.expectRevert();
        yardPair.swap(
            IERC721(testNFTB),
            finnNFTID,
            IERC721(testNFTA),
            nftID,
            finn
        );
    }

    function testSwapForNFTOutThatIsNotOwnedByPool() public sendNFTFirst addLiquiditySecond {
        vm.prank(address(yardPair));
        IERC721(testNFTA).transferFrom(address(yardPair), dick, nftID);

        vm.prank(address(yardRouter));
        vm.expectRevert();
        yardPair.swap(
            IERC721(testNFTB),
            finnNFTID,
            IERC721(testNFTA),
            nftID,
            finn
        );
    }

    function testSwapToZeroAddress() public sendNFTFirst addLiquiditySecond {
        vm.prank(address(yardRouter));
        vm.expectRevert();
        yardPair.swap(
            IERC721(testNFTB),
            finnNFTID,
            IERC721(testNFTA),
            nftID,
            zero
        );
    }

    function testSwapToProperReceiver(address receivers) public sendNFTFirst addLiquiditySecond {
        vm.assume(receivers.code.length == 0);
        (uint256 aSupplyBefore, uint256 bSupplyBefore) = yardPair.getAllReserves();
        (uint256 supplyABefore, uint256[] memory supplyAArrBefore) = yardPair.getReservesFor(IERC721(testNFTA));
        (uint256 supplyBBefore, uint256[] memory supplyBArrBefore) = yardPair.getReservesFor(IERC721(testNFTB));

        assertTrue((aSupplyBefore == 2) || (bSupplyBefore == 2));
        assertTrue((aSupplyBefore == 0) || (bSupplyBefore == 0));

        assertTrue(supplyABefore == 2);
        assertTrue(supplyAArrBefore.length == 2);

        assertTrue(supplyBBefore == 0);
        assertTrue(supplyBArrBefore.length == 0);

        vm.assume(receivers != zero);
        vm.prank(address(yardRouter));
        uint256 idOut = yardPair.swap(
            IERC721(testNFTB),
            finnNFTID,
            IERC721(testNFTA),
            nftID,
            receivers
        );

        assertTrue(idOut == nftID);
        assertTrue(IERC721(testNFTA).ownerOf(nftID) == receivers);

        (uint256 aSupply, uint256 bSupply) = yardPair.getAllReserves();
        (uint256 supplyA, uint256[] memory supplyAArr) = yardPair.getReservesFor(IERC721(testNFTA));
        (uint256 supplyB, uint256[] memory supplyBArr) = yardPair.getReservesFor(IERC721(testNFTB));

        assertTrue((aSupply == 1) && (bSupply == 1));

        assertTrue(supplyA == 1);
        assertTrue(supplyAArr.length == 1);

        assertTrue(supplyB == 1);
        assertTrue(supplyBArr.length == 1);
    }

    function testSwapReentrancy() public sendNFTFirst addLiquiditySecond {
        vm.prank(address(yardRouter));
        yardPair.swap(
            IERC721(testNFTB),
            finnNFTID,
            IERC721(testNFTA),
            nftID,
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
        yardPair.swap(
            IERC721(testNFTB),
            finnNFTID,
            IERC721(testNFTA),
            nftID,
            address(this)
        );

        return IERC721Receiver.onERC721Received.selector;
    }
}