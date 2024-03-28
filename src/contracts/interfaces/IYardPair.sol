// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

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

    function addLiquidity(
        IERC721 nftIn,
        uint256 idIn,
        address from,
        address to
    ) external returns (uint256 wId);

    function removeLiquidity(
        IERC721 nftOut,
        uint256 idOut,
        uint256 wId,
        address from,
        address to
    ) external returns (uint256 _idOut);

    function swap(
        IERC721 nftIn,
        uint256 idIn,
        IERC721 nftOut,
        uint256 idOut,
        address to
    ) external returns (uint256 _idOut);

    function claimRewards(address lpProvider) external returns (uint256 reward);

    function getAllReserves() external view returns (uint256, uint256);

    function getReservesFor(IERC721 nft) external view returns (uint256, uint256[] memory);

    function calculateRewards(address lpProvider) external view returns (uint256);
}