// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./YardFactory.t.sol";

contract YardFactoryCreatePairTest is YardFactoryTest {
    function testCreatePairByCallFromNonRouter(address hackers) public completeSetup {
        vm.assume((hackers != zero) && (hackers != address(yardRouter)));

        uint256[] memory testNFTAs = new uint256[] (testNFTA.getMintedTokensArray().length);
        uint256[] memory testNFTBs = new uint256[] (testNFTB.getMintedTokensArray().length);

        for (uint256 i; i < testNFTA.getMintedTokensArray().length; i++) {
            testNFTAs[i] = testNFTA.getMintedTokensArray()[i];
            testNFTBs[i] = testNFTB.getMintedTokensArray()[i];
        }

        vm.expectRevert();
        vm.prank(hackers);

        yardFactory.createPair(
            IERC721(testNFTA),
            testNFTAs,
            IERC721(testNFTB),
            testNFTBs,
            pairOwner,
            FIFTY_CENTS,
            address(feeToken),
            address(yardNFTWrapper),
            dick
        );
    }

    function testCreatePairWithTheSameNFTs() public completeSetup {
        uint256[] memory testNFTAs = new uint256[] (testNFTA.getMintedTokensArray().length);
        uint256[] memory testNFTBs = new uint256[] (testNFTB.getMintedTokensArray().length);

        for (uint256 i; i < testNFTA.getMintedTokensArray().length; i++) {
            testNFTAs[i] = testNFTA.getMintedTokensArray()[i];
            testNFTBs[i] = testNFTB.getMintedTokensArray()[i];
        }

        vm.expectRevert();
        vm.prank(address(yardRouter));

        yardFactory.createPair(
            IERC721(testNFTA),
            testNFTAs,
            IERC721(testNFTA),
            testNFTBs,
            pairOwner,
            FIFTY_CENTS,
            address(feeToken),
            address(yardNFTWrapper),
            dick
        );
    }

    function testCreatePairWithUnSettableFee(uint256 fee) public completeSetup {
        vm.assume((fee != TEN_CENTS) && (fee != THIRTY_CENTS) && (fee != FIFTY_CENTS));

        uint256[] memory testNFTAs = new uint256[] (testNFTA.getMintedTokensArray().length);
        uint256[] memory testNFTBs = new uint256[] (testNFTB.getMintedTokensArray().length);

        for (uint256 i; i < testNFTA.getMintedTokensArray().length; i++) {
            testNFTAs[i] = testNFTA.getMintedTokensArray()[i];
            testNFTBs[i] = testNFTB.getMintedTokensArray()[i];
        }

        vm.expectRevert();
        vm.prank(address(yardRouter));

        yardFactory.createPair(
            IERC721(testNFTA),
            testNFTAs,
            IERC721(testNFTB),
            testNFTBs,
            pairOwner,
            fee,
            address(feeToken),
            address(yardNFTWrapper),
            dick
        );
    }

    function testCreatePairWithEmptyArray() public completeSetup {
        address newPair;
        uint256[] memory testNFTAs = new uint256[] (0);
        uint256[] memory testNFTBs = new uint256[] (testNFTB.getMintedTokensArray().length);

        for (uint256 i; i < testNFTA.getMintedTokensArray().length; i++) {
            testNFTBs[i] = testNFTB.getMintedTokensArray()[i];
        }

        vm.expectRevert();
        vm.prank(address(yardRouter));

        newPair = yardFactory.createPair(
            IERC721(testNFTA),
            testNFTAs,
            IERC721(testNFTB),
            testNFTBs,
            pairOwner,
            FIFTY_CENTS,
            address(feeToken),
            address(yardNFTWrapper),
            dick
        );
    }

    function testCreatePairWithUnmatchedArrays() public completeSetup {
        address newPair;
        uint256[] memory testNFTAs = new uint256[] (1);
        uint256[] memory testNFTBs = new uint256[] (testNFTB.getMintedTokensArray().length);

        for (uint256 i; i < testNFTA.getMintedTokensArray().length; i++) {
            if (i == 0) {
                testNFTAs[i] = testNFTA.getMintedTokensArray()[i];
            }

            testNFTBs[i] = testNFTB.getMintedTokensArray()[i];
        }

        vm.expectRevert();
        vm.prank(address(yardRouter));

        newPair = yardFactory.createPair(
            IERC721(testNFTA),
            testNFTAs,
            IERC721(testNFTB),
            testNFTBs,
            pairOwner,
            FIFTY_CENTS,
            address(feeToken),
            address(yardNFTWrapper),
            dick
        );
    }

    function testCreatePairWithCorrectArguments() public completeSetup {
        address newPair;
        uint256 lastPoolCount = yardFactory.poolCount();

        assertTrue(yardFactory.getPair(IERC721(testNFTA), IERC721(testNFTB)) == zero);
        assertTrue(yardFactory.getPair(IERC721(testNFTB), IERC721(testNFTA)) == zero);

        uint256[] memory testNFTAs = new uint256[] (testNFTA.getMintedTokensArray().length);
        uint256[] memory testNFTBs = new uint256[] (testNFTB.getMintedTokensArray().length);

        for (uint256 i; i < testNFTA.getMintedTokensArray().length; i++) {
            testNFTAs[i] = testNFTA.getMintedTokensArray()[i];
            testNFTBs[i] = testNFTB.getMintedTokensArray()[i];
        }

        vm.prank(address(yardRouter));

        newPair = yardFactory.createPair(
            IERC721(testNFTA),
            testNFTAs,
            IERC721(testNFTB),
            testNFTBs,
            pairOwner,
            FIFTY_CENTS,
            address(feeToken),
            address(yardNFTWrapper),
            dick
        );

        assertTrue(newPair != zero);
        assertTrue(yardNFTWrapper.allowedPairs(newPair));
        assertTrue((yardFactory.poolCount() - lastPoolCount) == 1);
        assertTrue(yardFactory.getPair(IERC721(testNFTA), IERC721(testNFTB)) == newPair);
        assertTrue(yardFactory.getPair(IERC721(testNFTB), IERC721(testNFTA)) == newPair);
    }

    function testCreatePairForExistingPairIEAddLiquidityWithEmptyArray() public completeSetup {
        address newPair;
        uint256[] memory testNFTAs = new uint256[] (testNFTA.getMintedTokensArray().length);
        uint256[] memory testNFTBs = new uint256[] (testNFTB.getMintedTokensArray().length);

        for (uint256 i; i < testNFTA.getMintedTokensArray().length; i++) {
            testNFTAs[i] = testNFTA.getMintedTokensArray()[i];
            testNFTBs[i] = testNFTB.getMintedTokensArray()[i];
        }

        vm.prank(address(yardRouter));

        newPair = yardFactory.createPair(
            IERC721(testNFTA),
            testNFTAs,
            IERC721(testNFTB),
            testNFTBs,
            pairOwner,
            FIFTY_CENTS,
            address(feeToken),
            address(yardNFTWrapper),
            dick
        );

        uint256[] memory testNFTA2s = new uint256[] (0);
        uint256[] memory testNFTB2s = new uint256[] (testNFTB.getMintedTokensArray().length);

        for (uint256 i; i < testNFTA.getMintedTokensArray().length; i++) {
            testNFTB2s[i] = testNFTB.getMintedTokensArray()[i];
        }

        vm.expectRevert();
        vm.prank(address(yardRouter));

        yardFactory.createPair(
            IERC721(testNFTA),
            testNFTA2s,
            IERC721(testNFTB),
            testNFTB2s,
            pairOwner,
            FIFTY_CENTS,
            address(feeToken),
            address(yardNFTWrapper),
            dick
        );
    }

    function testCreatePairForExistingPairIEAddLiquidityWithUnmatchedArrays() public completeSetup {
        address newPair;
        uint256[] memory testNFTAs = new uint256[] (testNFTA.getMintedTokensArray().length);
        uint256[] memory testNFTBs = new uint256[] (testNFTB.getMintedTokensArray().length);

        for (uint256 i; i < testNFTA.getMintedTokensArray().length; i++) {
            testNFTAs[i] = testNFTA.getMintedTokensArray()[i];
            testNFTBs[i] = testNFTB.getMintedTokensArray()[i];
        }

        vm.prank(address(yardRouter));

        newPair = yardFactory.createPair(
            IERC721(testNFTA),
            testNFTAs,
            IERC721(testNFTB),
            testNFTBs,
            pairOwner,
            FIFTY_CENTS,
            address(feeToken),
            address(yardNFTWrapper),
            dick
        );

        uint256[] memory testNFTA2s = new uint256[] (1);
        uint256[] memory testNFTB2s = new uint256[] (testNFTB.getMintedTokensArray().length);

        for (uint256 i; i < testNFTA.getMintedTokensArray().length; i++) {
            if (i == 0) {
                testNFTA2s[i] = testNFTA.getMintedTokensArray()[i];
            }

            testNFTB2s[i] = testNFTB.getMintedTokensArray()[i];
        }

        vm.expectRevert();
        vm.prank(address(yardRouter));

        newPair = yardFactory.createPair(
            IERC721(testNFTA),
            testNFTA2s,
            IERC721(testNFTB),
            testNFTB2s,
            pairOwner,
            FIFTY_CENTS,
            address(feeToken),
            address(yardNFTWrapper),
            dick
        );
    }

    function testCreatePairForExistingPairIEAddLiquidityWithUnownedTokens() public completeSetup {
        address newPair;
        uint256[] memory testNFTAs = new uint256[] (testNFTA.getMintedTokensArray().length);
        uint256[] memory testNFTBs = new uint256[] (testNFTB.getMintedTokensArray().length);

        for (uint256 i; i < testNFTA.getMintedTokensArray().length; i++) {
            testNFTAs[i] = testNFTA.getMintedTokensArray()[i];
            testNFTBs[i] = testNFTB.getMintedTokensArray()[i];
        }

        vm.prank(address(yardRouter));

        newPair = yardFactory.createPair(
            IERC721(testNFTA),
            testNFTAs,
            IERC721(testNFTB),
            testNFTBs,
            pairOwner,
            FIFTY_CENTS,
            address(feeToken),
            address(yardNFTWrapper),
            dick
        );

        vm.expectRevert();
        vm.prank(address(yardRouter));

        yardFactory.createPair(
            IERC721(testNFTA),
            testNFTAs,
            IERC721(testNFTB),
            testNFTBs,
            pairOwner,
            FIFTY_CENTS,
            address(feeToken),
            address(yardNFTWrapper),
            dick
        );
    }

    function testOnERC721Received() public {
        assertTrue(
            yardFactory.onERC721Received(
                address(testNFTA),
                address(testNFTB),
                block.timestamp,
                bytes("YardFactory")
            ) == IERC721Receiver.onERC721Received.selector
        );
    }
}