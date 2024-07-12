// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./YardFactory.t.sol";

contract YardFactoryGetPairTest is YardFactoryTest {
    function testGetPairForInExistentPair(address nftA, address nftB) public {
        IERC721 NFTA = IERC721(nftA);
        IERC721 NFTB = IERC721(nftB);

        assertTrue(yardFactory.getPair(NFTA, NFTB) == zero);
        assertTrue(yardFactory.getPair(NFTB, NFTA) == zero);
    }

    function testGetPairForExistentPair() public completeSetup createPairForTwoNFTs {
        assertTrue(yardFactory.getPair(IERC721(testNFTA), IERC721(testNFTB)) == createdPair);
        assertTrue(yardFactory.getPair(IERC721(testNFTB), IERC721(testNFTA)) == createdPair);
    }
}