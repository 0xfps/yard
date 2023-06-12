// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
* @title IYardRouter
* @author fps (@0xfps).
* @dev Interface for the `YardRouter` contract.
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

    function addLiquidity(
        IERC721 nftIn,
        uint256 idIn,
        address to
    ) external returns (uint256 wId);

    function addBatchLiquidity(
        IERC721 nftIn,
        uint256[] memory idsIn,
        address to
    ) external returns (uint256[] memory wId);

    function removeLiquidity(
        IERC721 nftOut,
        uint256 idOut,
        uint256 wId,
        address to
    ) external returns (uint256 _idOut);

    function removeBatchLiquidity(
        IERC721 nftOut,
        uint256[] memory idsOut,
        uint256[] memory wIds,
        address to
    ) external returns (uint256[] memory _idsOut);

    function newPair(
        IERC721 nftA,
        uint256[] memory idsA,
        IERC721 nftB,
        uint256[] memory idsB
    ) external returns (address pair);

    function swapNFTForExactNFT(
        IERC721[] memory path,
        uint256 idIn,
        uint256 idOut,
        address to
    ) external returns (uint256 _idOut);

    function swapBatchNFTsForExactNFTs(
        IERC721[] memory path,
        uint256[] memory idsIn,
        uint256[] memory idsOut,
        address to
    ) external returns (uint256[] memory _idsOut);

    function swapNFTForArbitraryNFT(
        IERC721[] memory path,
        uint256 idIn,
        address to
    ) external returns (uint256 _idOut);

    function swapBatchNFTsForArbitraryNFTs(
        IERC721[] memory path,
        uint256[] memory idsIn,
        address to
    ) external returns (uint256[] memory _idsOut);

    function takeRewards(
        IERC721 nftA,
        IERC721 nftB,
        address to
    ) external returns (uint256);

    function viewAllReserves(IERC721 nftA, IERC721 nftB)
        external
        view
        returns (uint256, uint256);

    function getPair(IERC721 nftA, IERC721 nftB) external returns (address pair);

    function getRewards(
        IERC721 nftA,
        IERC721 nftB,
        address lpProvider
    ) external view returns (uint256);
}