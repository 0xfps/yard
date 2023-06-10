// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
* @title IYardFactory
* @author fps (@0xfps).
* @dev Interface for the `YardFactory` contract.
*/

interface IYardFactory {
    function createPair(
        IERC721 nftA,
        uint256[] memory idsA,
        IERC721 nftB,
        uint256[] memory idsB
    ) external returns (address pair);

    function getPair(IERC721 nftA, IERC721 nftB) external returns (address pair);
}