// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
* @title IYardFactory
* @author fps (@0xfps).
* @dev Interface for the `YardFactory` contract.
*/

interface IYardFactory {
    event PairCreated(IERC721 nftA, IERC721 nftB, address indexed pair, address creator);

    function createPair(
        IERC721 nftA,
        uint256[] memory idsA,
        IERC721 nftB,
        uint256[] memory idsB,
        address creator,
        uint32 fee
    ) external returns (address pair);

    function getPair(address nftA, address nftB) external returns (address pair);
    function getNFTsAtPair(address pair) external view returns (address, address);
}