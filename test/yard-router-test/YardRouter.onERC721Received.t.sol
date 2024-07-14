// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./YardRouter.t.sol";

contract YardRouterOnERC721ReceivedTest is YardRouterTest {
    function testOnERC721Received() public {
        assertTrue(
            yardRouter.onERC721Received(
                address(testNFTA),
                address(testNFTB),
                block.timestamp,
                bytes("YardRouter")
            ) == IERC721Receiver.onERC721Received.selector
        );
    }
}