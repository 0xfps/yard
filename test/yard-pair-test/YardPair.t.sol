// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../__utils__/Addresses.sol";
import { FakeTestERC20 } from "../__utils__/FakeTestERC20.sol";
import { FakeTestERC721 } from "../__utils__/FakeTestERC721.sol";
import { YardFactory } from "../../src/contracts/YardFactory.sol";
import { YardNFTWrapper } from "../../src/contracts/utils/YardNFTWrapper.sol";
import { YardPair } from "../../src/contracts/YardPair.sol";
import { YardRouter } from "../../src/contracts/YardRouter.sol";

contract YardPairTest is Addresses {
    FakeTestERC20 public feeToken;
    FakeTestERC721 public testNFTA;
    FakeTestERC721 public testNFTB;
    YardFactory public yardFactory;
    YardNFTWrapper public yardNFTWrapper;
    YardPair public yardPair;
    YardRouter public yardRouter;

    function setUp() public {
        vm.startPrank(owner);
        yardFactory = new YardFactory();
        yardNFTWrapper = new YardNFTWrapper();

        yardNFTWrapper.setFactory(address(yardFactory));

        testNFTA = new FakeTestERC721();
        testNFTB = new FakeTestERC721();
        feeToken = new FakeTestERC20();
        yardRouter = new YardRouter(address(feeToken), address(yardNFTWrapper));

        feeToken.mint(finn, 500e6);
//        feeToken.mint(alice, 500e6);

        yardFactory.setWrapper(address(yardNFTWrapper));
        yardFactory.setRouter(address(yardRouter));

        testNFTA.mint(alice, 15); // [0 -> 14]
        testNFTB.mint(alice, 15); // [0 -> 14]

        testNFTA.mint(chris, 15); // [15 -> 29]
        testNFTB.mint(chris, 15); // [15 -> 29]

        testNFTA.mint(finn, 15); // [30 -> 44]
        testNFTB.mint(finn, 15); // [30 -> 44]

        yardPair = new YardPair(
            testNFTA,
            testNFTB,
            address(yardRouter),
            address(yardFactory),
            pairOwner,
            FIFTY_CENTS,
            address(feeToken),
            address(yardNFTWrapper)
        );

        vm.stopPrank();

        vm.prank(address(yardFactory));
        yardNFTWrapper.addPair(address(yardPair));
    }

    function testSetUp() public {
        assertTrue(address(yardPair) != zero);
    }
}