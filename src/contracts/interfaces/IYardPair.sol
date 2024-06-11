// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
* @title IYardPair
* @author fps (@0xfps).
* @dev Interface for the `YardPair` contract.
*/

interface IYardPair {
    event LiquidityAdded(IERC721 indexed nftIn, uint256 indexed idIn);
    event LiquidityRemoved(IERC721 indexed nftOut, uint256 indexed idOut);
    event RewardClaimed(address indexed lpProvider, uint256 indexed reward);
    event Swapped(
        IERC721 indexed nftIn,
        uint256 idIn,
        IERC721 indexed nftOut,
        uint256 idOut
    );

    /// @dev Add NFT liquidity to a pool.
    function addLiquidity(
        IERC721 nftIn,
        uint256 idIn,
        address from,
        address to
    ) external returns (uint256 wId);

    /// @dev Remove NFT liquidity from a pool.
    function removeLiquidity(
        IERC721 nftOut,
        uint256 idOut,
        uint256 wId,
        address from,
        address to
    ) external returns (uint256 _idOut);

    /// @dev Swap an `nftIn` for `nftOut` in a pool.
    function swap(
        IERC721 nftIn,
        uint256 idIn,
        IERC721 nftOut,
        uint256 idOut,
        address to
    ) external returns (uint256 _idOut);

    /// @dev Transfer `reward` owned by `lpProvider` to `lpProvider`.
    function claimRewards(address lpProvider) external returns (uint256 reward);

    /// @dev Returns a tuple of the number of NFTs, nftA and nftB in a pool.
    function getAllReserves() external view returns (uint256, uint256);

    /// @dev Returns a tuple of the number of NFTs, for `nft` in a pool.
    function getReservesFor(IERC721 nft) external view returns (uint256, uint256[] memory);

    /// @dev Calculate and return rewards claimable by `lpProvider`.
    function calculateRewards(address lpProvider) external view returns (uint256);
}