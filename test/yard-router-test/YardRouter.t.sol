// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../__utils__/Addresses.sol";
import { FakeTestERC20 } from "../__utils__/FakeTestERC20.sol";
import { FakeTestERC721 } from "../__utils__/FakeTestERC721.sol";
import { YardFactory } from "../../src/contracts/YardFactory.sol";
import { YardNFTWrapper } from "../../src/contracts/utils/YardNFTWrapper.sol";
import { YardPair } from "../../src/contracts/YardPair.sol";
import { YardRouter } from "../../src/contracts/YardRouter.sol";

contract YardRouterTest is Addresses {
    FakeTestERC20 public feeToken;
    FakeTestERC721 public testNFTA;
    FakeTestERC721 public testNFTB;
    FakeTestERC721 public testNFTC;
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
        testNFTC = new FakeTestERC721();

        feeToken = new FakeTestERC20();
        yardRouter = new YardRouter(address(feeToken), address(yardNFTWrapper));

        yardFactory.setWrapper(address(yardNFTWrapper));
        yardFactory.setRouter(address(yardRouter));

        testNFTA.mint(alice, 15); // [0 -> 14]
        testNFTB.mint(alice, 15); // [0 -> 14]
        testNFTC.mint(alice, 15); // [0 -> 14]

        testNFTA.mint(chris, 15); // [15 -> 29]
        testNFTB.mint(chris, 15); // [15 -> 29]
        testNFTC.mint(chris, 15); // [15 -> 29]

        testNFTA.mint(finn, 15); // [30 -> 44]
        testNFTB.mint(finn, 15); // [30 -> 44]
        testNFTC.mint(finn, 15); // [30 -> 44]

        vm.stopPrank();

        vm.startPrank(alice);
        testNFTA.approveAll(alice, address(yardRouter), true);
        testNFTB.approveAll(alice, address(yardRouter), true);
        testNFTC.approveAll(alice, address(yardRouter), true);
        vm.stopPrank();

        vm.startPrank(chris);
        testNFTA.approveAll(chris, address(yardRouter), true);
        testNFTB.approveAll(chris, address(yardRouter), true);
        testNFTC.approveAll(chris, address(yardRouter), true);
        vm.stopPrank();

        vm.startPrank(finn);
        testNFTA.approveAll(finn, address(yardRouter), true);
        testNFTB.approveAll(finn, address(yardRouter), true);
        testNFTC.approveAll(finn, address(yardRouter), true);
        vm.stopPrank();
    }

    modifier completeSetup() {
        vm.prank(owner);
        yardRouter.setFactory(address(yardFactory));

        _;
    }

    function testSetUp() public {
        assertTrue(address(yardRouter) != zero);
    }

    function _mintTokens() internal {
        feeToken.mint(alice, 500e6);
        feeToken.mint(chris, 500e6);
        feeToken.mint(finn, 500e6);

        vm.prank(alice);
        feeToken.approve(address(yardRouter), 500e6);

        vm.prank(chris);
        feeToken.approve(address(yardRouter), 500e6);

        vm.prank(finn);
        feeToken.approve(address(yardRouter), 500e6);
    }

    function _skipTime() internal {
        skip(31 days);
    }

    function _createPair() internal returns (address newPair) {
        uint256[] memory ids = _getIDsFor(alice);

        vm.prank(alice);
        newPair = yardRouter.createPair(
            IERC721(testNFTA),
            ids,
            IERC721(testNFTB),
            ids,
            FIFTY_CENTS,
            alice
        );
    }

    function _getOnePath() internal view returns (IERC721[] memory) {
        IERC721[] memory path = new IERC721[] (1);
        path[0] = IERC721(address(testNFTA));
        return path;
    }

    function _getDirtyPath() internal view returns (IERC721[] memory) {
        IERC721[] memory path = new IERC721[] (2);
        path[0] = IERC721(address(uint160(block.timestamp)));
        path[1] = IERC721(address(uint160(block.timestamp)));
        return path;
    }

    function _getTwoPaths() internal view returns (IERC721[] memory) {
        IERC721[] memory path = new IERC721[] (2);
        path[0] = IERC721(address(testNFTA));
        path[1] = IERC721(address(testNFTB));
        return path;
    }

    function _getThreePaths() internal view returns (IERC721[] memory) {
        IERC721[] memory path = new IERC721[] (3);
        path[0] = IERC721(address(testNFTA));
        path[1] = IERC721(address(testNFTB));
        path[2] = IERC721(address(testNFTC));
        return path;
    }

    function _getIDsFor(address owner) internal view returns (uint256[] memory) {
        uint8 limit = 5;
        uint256 start;
        uint256[] memory ids = new uint256[] (limit);

        if (owner == alice) {
            for (uint256 i; i < limit; i++) {
                ids[i] = i;
            }
        } else if (owner == chris) {
            start = 15;
            for (uint256 i = start; i < (start + limit); i++) {
                ids[i - start] = i;
            }
        } else {
            start = 50;
            for (uint256 i = start; i < (start + limit); i++) {
                ids[i - start] = i;
            }
        }

        return ids;
    }
}