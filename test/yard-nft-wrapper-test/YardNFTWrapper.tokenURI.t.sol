// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./YardNFTWrapper.addPair.t.sol";

contract YardNFTWrapperTokenURITest is YardNFTWrapperAddPairTest {
    modifier setFactoryAndPair() {
        testAddProperPairShouldPass();
        _;
    }

    function testTokenURIMatchesAfterWrap() public setFactoryAndPair {
        vm.prank(pair);
        uint256 wrappedID = yardNFTWrapper.wrap(ERC721(cryptoPunks), validId, alice);
        string memory cryptoPunk8000URI = ERC721(cryptoPunks).tokenURI(validId);
        string memory wrapped8000URI = yardNFTWrapper.tokenURI(wrappedID);

        assertTrue(yardNFTWrapper.ownerOf(wrappedID) == alice);
        assertTrue(keccak256(bytes(cryptoPunk8000URI)) == keccak256(bytes(wrapped8000URI)));
    }
}