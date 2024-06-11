// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
* @title    IYardRouter
* @author   fps (@0xfps).
* @dev      Interface for the `YardRouter` contract.
*/

interface IYardRouter {
    event BatchLiquidityAdded(IERC721 indexed nftIn, uint256[] idsIn);
    event BatchLiquidityRemoved(IERC721 indexed nftOut, uint256[] idsOut);
    event BatchSwapped(
        IERC721 indexed nftIn,
        uint256[] idsIn,
        IERC721 indexed nftOut,
        uint256[] idsOut
    );
    event LiquidityAdded(IERC721 indexed nftIn, uint256 indexed idIn);
    event LiquidityRemoved(IERC721 indexed nftOut, uint256 indexed idOut);
    event RewardClaimed(address indexed lpProvider, uint256 indexed reward);
    event Swapped(
        IERC721 indexed nftIn,
        uint256 idIn,
        IERC721 indexed nftOut,
        uint256 idOut
    );

    /// @dev Add liquidity of a single NFT to a pool.
    function addLiquidity(
        IERC721 nftA,
        IERC721 nftB,
        IERC721 nftIn,
        uint256 idIn,
        address to
    ) external returns (uint256 wId);

    /// @dev Add liquidity for a group of NFTs to a pool.
    function addBatchLiquidity(
        IERC721 nftA,
        IERC721 nftB,
        IERC721 nftIn,
        uint256[] memory idsIn,
        address to
    ) external returns (uint256[] memory wId);

    /// @dev Remove liquidity of a single NFT in a pool.
    function removeLiquidity(
        IERC721 nftA,
        IERC721 nftB,
        IERC721 nftOut,
        uint256 idOut,
        uint256 wId,
        address to
    ) external returns (uint256 _idOut);

    /// @dev Remove liquidity for a group of NFTs in a pool.
    function removeBatchLiquidity(
        IERC721 nftA,
        IERC721 nftB,
        IERC721 nftOut,
        uint256[] memory idsOut,
        uint256[] memory wIds,
        address to
    ) external returns (uint256[] memory _idsOut);

    /// @dev Deploys a new `YardPair` contract by calling the `YardFactory`.
    function createPair(
        IERC721 nftA,
        uint256[] memory idsA,
        IERC721 nftB,
        uint256[] memory idsB
    ) external returns (address pair);

    /// @dev Swap one `idIn` for `idOut` in a pair and send them to `to`.
    function swapNFTForExactNFT(
        IERC721[] memory path,
        uint256 idIn,
        uint256 idOut,
        address to
    ) external returns (uint256 _idOut);

    /// @dev Swap a group of `idsIn` for `idsOut` in a pair and send them to `to`.
    function swapBatchNFTsForExactNFTs(
        IERC721[] memory path,
        uint256[] memory idsIn,
        uint256[] memory idsOut,
        address to
    ) external returns (uint256[] memory _idsOut);

    /// @dev Swap one `idIn` for a random NFT in a pair and send them to `to`.
    function swapNFTForArbitraryNFT(
        IERC721[] memory path,
        uint256 idIn,
        address to
    ) external returns (uint256 _idOut);

    /// @dev Swap a group of `idsIn` for random NFTs in a pair and send them to `to`.
    function swapBatchNFTsForArbitraryNFTs(
        IERC721[] memory path,
        uint256[] memory idsIn,
        address to
    ) external returns (uint256[] memory _idsOut);

    /// @dev Take rewards for `msg.sender` in the pair.
    function takeRewards(
        IERC721 nftA,
        IERC721 nftB,
        address to
    ) external returns (uint256);

    /// @dev Returns a tuple of the number of NFTs, nftA and nftB in a pair.
    function viewAllReserves(IERC721 nftA, IERC721 nftB)
        external
        view
        returns (uint256, uint256);

    /// @dev Return the address of the `YardPair` contract for [nftA][nftB].
    function getPair(IERC721 nftA, IERC721 nftB) external returns (address pair);

    /// @dev Calculate and return rewards claimable by `lpProvider`.
    function getRewards(
        IERC721 nftA,
        IERC721 nftB,
        address lpProvider
    ) external view returns (uint256);
}