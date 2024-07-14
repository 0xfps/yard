// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./YardPair.t.sol";

contract YardPairAddLiquidityTest is YardPairTest {
    uint256 nftID = 5;

    modifier sendNFTFirst() {
        vm.prank(alice);
        testNFTA.safeTransferFrom(alice, address(yardPair), nftID);

        _;
    }

    function testAddLiquidityByCallFromNonFactoryOrRouter(address hackers) public {
        vm.assume((hackers != zero) && (hackers != address(yardFactory) && (hackers != address(yardRouter))));
        vm.prank(hackers);
        vm.expectRevert();
        yardPair.addLiquidity(
            IERC721(testNFTA),
            4,
            hackers,
            hacker
        );
    }

    function testAddLiquidityWithNFTNotNFTAOrNFTB(address nft) public {
        vm.assume((nft != address(testNFTA)) && (nft != address(testNFTB)));
        vm.prank(address(yardRouter));
        vm.expectRevert();
        yardPair.addLiquidity(
            IERC721(nft),
            4,
            alice,
            dick
        );
    }

    function testAddLiquidityWithNFTNotSentToPair() public {
        vm.prank(address(yardRouter));
        vm.expectRevert();
        yardPair.addLiquidity(
            IERC721(testNFTA),
            4,
            alice,
            dick
        );
    }

    function testAddLiquidityWhenNFTAlreadyInPool() public sendNFTFirst {
        vm.prank(address(yardRouter));
        yardPair.addLiquidity(
            IERC721(testNFTA),
            nftID,
            alice,
            dick
        );

        vm.prank(address(yardRouter));
        vm.expectRevert();
        yardPair.addLiquidity(
            IERC721(testNFTA),
            nftID,
            alice,
            dick
        );
    }

    function testAddLiquidityWithToAsZeroAddress() public sendNFTFirst {
        vm.prank(address(yardRouter));
        vm.expectRevert();
        yardPair.addLiquidity(
            IERC721(testNFTA),
            nftID,
            alice,
            zero
        );
    }

    function testAddLiquidityProperlyWithRecipientAsAnyAddress(address receiver) public sendNFTFirst {
        vm.assume(receiver != zero);
        vm.prank(address(yardRouter));
        uint256 receivedId = yardPair.addLiquidity(
            IERC721(testNFTA),
            nftID,
            alice,
            receiver
        );

        assertTrue(yardNFTWrapper.ownerOf(receivedId) == receiver);

        (uint256 aSupply, uint256 bSupply) = yardPair.getAllReserves();
        (uint256 supply, uint256[] memory supplyArr) = yardPair.getReservesFor(IERC721(testNFTA));

        assertTrue((aSupply == 1) || (bSupply == 1));
        assertTrue(supply == 1);
        assertTrue(supplyArr[0] == nftID);
        assertTrue(supplyArr.length == 1);
    }
}