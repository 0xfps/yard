// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
* @title    IYardFactory
* @author   fps (@0xfps).
* @dev      Interface for the `YardFactory` contract.
*/

interface IYardFactory {
    event PairCreated(IERC721 nftA, IERC721 nftB, address indexed pair);

    /// @dev    Returns how many pools the factory has deployed.
    /// @return count Count.
    function poolCount() external view returns (uint256 count);

    /// @dev    Deploys a new `YardPair` contract.
    /// @return pair Address of new pair.
    function createPair(
        IERC721 nftA,
        uint256[] memory idsA,
        IERC721 nftB,
        uint256[] memory idsB,
        address _pairOwner,
        uint256 _fee,
        address _feeToken,
        address _yardWrapper,
        address _to
    ) external returns (address pair);

    /// @dev    Return the address of the `YardPair` contract for [nftA][nftB].
    /// @return pair Address of pair for `nftA` and `nftB`.
    function getPair(IERC721 nftA, IERC721 nftB) external view returns (address pair);
}