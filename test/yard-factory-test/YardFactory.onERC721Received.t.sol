// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./YardFactory.t.sol";

contract YardFactoryCreatePairTest is YardFactoryTest {
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