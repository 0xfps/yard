// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./YardRouter.t.sol";

contract YardRouterSwapNFTForExactNFTsAcrossPoolsAcrossPoolsTest is YardRouterTest {
    function _settingUp() internal {
        uint256[] memory ids = _getIDsFor(alice);
        uint256[] memory secondIds = new uint256[] (5);

        for (uint256 i = secondIds.length; i < (secondIds.length + 5); i++) {
            secondIds[i - secondIds.length] = i;
        }

        vm.prank(alice);
        yardRouter.createPair(
            IERC721(testNFTA),
            ids,
            IERC721(testNFTB),
            ids,
            FIFTY_CENTS,
            alice
        );

        vm.prank(alice);
        yardRouter.createPair(
            IERC721(testNFTB),
            secondIds,
            IERC721(testNFTC),
            ids,
            FIFTY_CENTS,
            alice
        );
    }

    function testSwapNFTForExactNFTsAcrossPoolsWithPathNotEqualThanTwo() public completeSetup {
        _settingUp();

        IERC721[] memory path = _getOnePath();
        uint256[] memory idsOut = new uint256[] (7);

        for (uint256 i = idsOut.length; i < (idsOut.length + 5); i++) {
            idsOut[i - idsOut.length] = i;
        }

        vm.expectRevert();
        vm.prank(chris);

        yardRouter.swapExactNFTsForExactNFTsAcrossPools(
            path,
            16,
            idsOut,
            chris
        );
    }

    function testSwapNFTForExactNFTsAcrossPoolsWithIdsOutNotEqualToLengthOfPathMinusOne() public completeSetup {
        _settingUp();

        IERC721[] memory path = _getThreePaths();
        uint256[] memory idsOut = new uint256[] (7);

        for (uint256 i = idsOut.length; i < (idsOut.length + 5); i++) {
            idsOut[i - idsOut.length] = i;
        }

        vm.expectRevert();
        vm.prank(chris);

        yardRouter.swapExactNFTsForExactNFTsAcrossPools(
            path,
            16,
            idsOut,
            chris
        );
    }

    function testSwapNFTForExactNFTsAcrossPoolsToZeroAddress() public completeSetup {
        _settingUp();

        IERC721[] memory path = _getThreePaths();
        uint256[] memory idsOut = new uint256[] (2);
        idsOut[0] = 4;
        idsOut[1] = 2;
        uint256 idIn = 16;

        vm.expectRevert();
        vm.prank(chris);

        yardRouter.swapExactNFTsForExactNFTsAcrossPools(
            path,
            idIn,
            idsOut,
            zero
        );
    }

    function testSwapNFTForExactNFTsAcrossPoolsWithInExistentPair() public completeSetup {
        _settingUp();

        IERC721[] memory path = new IERC721[] (3);
        path[0] = IERC721(address(1));
        path[1] = IERC721(testNFTB);
        path[2] = IERC721(address(3));

        uint256[] memory idsOut = new uint256[] (2);
        idsOut[0] = 4;
        idsOut[1] = 2;
        uint256 idIn = 16;

        vm.expectRevert();
        vm.prank(chris);

        yardRouter.swapExactNFTsForExactNFTsAcrossPools(
            path,
            idIn,
            idsOut,
            dick
        );
    }

    function testSwapNFTForExactNFTsAcrossPoolsWithInExistentPairTwo() public completeSetup {
        _settingUp();
        _mintTokens();

        IERC721[] memory path = new IERC721[] (3);
        path[0] = IERC721(testNFTA);
        path[1] = IERC721(testNFTB);
        path[2] = IERC721(address(3));

        uint256[] memory idsOut = new uint256[] (2);
        idsOut[0] = 4;
        idsOut[1] = 2;
        uint256 idIn = 16;

        vm.expectRevert();
        vm.prank(chris);

        yardRouter.swapExactNFTsForExactNFTsAcrossPools(
            path,
            idIn,
            idsOut,
            dick
        );
    }

    function testSwapNFTForExactNFTsAcrossPoolsWithWithoutApproval() public completeSetup {
        _settingUp();

        IERC721[] memory path = new IERC721[] (3);
        path[0] = IERC721(testNFTA);
        path[1] = IERC721(testNFTB);
        path[2] = IERC721(testNFTC);

        uint256[] memory idsOut = new uint256[] (2);
        idsOut[0] = 4;
        idsOut[1] = 2;
        uint256 idIn = 16;

        vm.expectRevert();
        vm.prank(chris);

        yardRouter.swapExactNFTsForExactNFTsAcrossPools(
            path,
            idIn,
            idsOut,
            dick
        );
    }

    function testSwapNFTForExactNFTsAcrossPoolsToReceiver(address receivers) public completeSetup {
        vm.assume((receivers.code.length == 0) && (receivers != zero));
        _settingUp();
        _mintTokens();

        IERC721[] memory path = new IERC721[] (3);
        path[0] = IERC721(testNFTA);
        path[1] = IERC721(testNFTB);
        path[2] = IERC721(testNFTC);

        uint256[] memory idsOut = new uint256[] (2);
        idsOut[0] = 4;
        idsOut[1] = 2;
        uint256 idIn = 16;

        vm.prank(chris);

        yardRouter.swapExactNFTsForExactNFTsAcrossPools(
            path,
            idIn,
            idsOut,
            receivers
        );

        assertTrue(testNFTB.ownerOf(idsOut[0]) == address(yardRouter.getPair(IERC721(testNFTB), IERC721(testNFTC))));
        assertTrue(testNFTC.ownerOf(idsOut[1]) == receivers);
    }
}