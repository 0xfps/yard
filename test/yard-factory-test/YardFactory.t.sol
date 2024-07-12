// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../__utils__/Addresses.sol";
import { FakeTestERC20 } from "../__utils__/FakeTestERC20.sol";
import { FakeTestERC721 } from "../__utils__/FakeTestERC721.sol";
import { YardFactory } from "../../src/contracts/YardFactory.sol";
import { YardNFTWrapper } from "../../src/contracts/utils/YardNFTWrapper.sol";
import { YardRouter } from "../../src/contracts/YardRouter.sol";

contract YardFactoryTest is Addresses {
    YardFactory public yardFactory;
    YardNFTWrapper public yardNFTWrapper;
    YardRouter public yardRouter;
    FakeTestERC20 public feeToken;
    FakeTestERC721 public testNFTA;
    FakeTestERC721 public testNFTB;
    address public createdPair;

    function setUp() public {
        vm.startPrank(owner);
        yardFactory = new YardFactory();
        yardNFTWrapper = new YardNFTWrapper();

        yardNFTWrapper.setFactory(address(yardFactory));

        testNFTA = new FakeTestERC721();
        testNFTB = new FakeTestERC721();
        feeToken = new FakeTestERC20();
        yardRouter = new YardRouter(address(feeToken), address(yardNFTWrapper));

        testNFTA.mint(address(yardFactory), 5);
        testNFTB.mint(address(yardFactory), 5);

        vm.stopPrank();
    }

    modifier completeSetup() {
        vm.startPrank(owner);
        yardFactory.setWrapper(address(yardNFTWrapper));
        yardFactory.setRouter(address(yardRouter));
        vm.stopPrank();

        _;
    }

    modifier createPairForTwoNFTs() {
        vm.startPrank(address(yardRouter));

        createdPair = yardFactory.createPair(
            IERC721(testNFTA),
            testNFTA.getMintedTokensArray(),
            IERC721(testNFTB),
            testNFTB.getMintedTokensArray(),
            pairOwner,
            FIFTY_CENTS,
            address(feeToken),
            address(yardNFTWrapper),
            dick
        );

        vm.stopPrank();

        _;
    }

    function testSetUp() public {
        assertTrue(address(yardFactory) != zero);
        assertTrue(address(yardNFTWrapper) != zero);
        assertTrue(address(yardRouter) != zero);
        assertTrue(address(feeToken) != zero);
    }
}