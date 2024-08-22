// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./YardRouter.t.sol";

contract YardRouterAddLiquidityTest is YardRouterTest {
    function testAddLiquidityCheckValidityWhereNFTInIsEqualToNFTB() public completeSetup {
        vm.prank(alice);
        vm.expectRevert();
        yardRouter.addLiquidity(
            IERC721(testNFTA),
            IERC721(testNFTA),
            IERC721(testNFTA),
            4,
            alice
        );
    }

    function testAddLiquidityCheckValidityWhereNFTInIsNotEqualToNFTAAndNFTB(address nft) public completeSetup {
        vm.assume((nft != address(testNFTA)) && (nft != address(testNFTB)));
        vm.prank(alice);
        vm.expectRevert();
        yardRouter.addLiquidity(
            IERC721(testNFTA),
            IERC721(testNFTB),
            IERC721(nft),
            4,
            alice
        );
    }

    function testAddLiquidityWithUnOwnedNFTIn(uint256 idIn) public completeSetup {
        _createPair();

        vm.assume(idIn > 14);
        vm.prank(alice);
        vm.expectRevert();
        yardRouter.addLiquidity(
            IERC721(testNFTA),
            IERC721(testNFTB),
            IERC721(testNFTA),
            idIn,
            alice
        );
    }

    function testAddProperLiquiditySendToReceiver(address receivers) public completeSetup {
        vm.assume((receivers.code.length == 0) && (receivers != zero));
        _createPair();

        assertTrue(yardRouter.getLiquidityProvidedPairs(chris).length == 0);
        uint8 idAdded = 16;
        vm.prank(chris);
        uint256 wId = yardRouter.addLiquidity(
            IERC721(testNFTA),
            IERC721(testNFTB),
            IERC721(testNFTA),
            idAdded,
            receivers
        );

        assertTrue(testNFTA.ownerOf(idAdded) == address(yardRouter.getPair(IERC721(testNFTA), IERC721(testNFTB))));
        assertTrue(yardNFTWrapper.ownerOf(wId) == receivers);
        assertTrue(yardRouter.getLiquidityProvidedPairs(chris).length != 0);
        assertTrue(yardRouter.getLiquidityProvidedPairs(chris).length == 1);
    }
}