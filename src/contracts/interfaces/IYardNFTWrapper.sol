// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title IYardNFTWrapper
 * @author fps (@0xfps).
 * @dev Interface for interacting with Yard NFT Wrapper.
 * @notice   The Yard NFT Wrapper has a singular function of wrapping NFTs
 *           by keeping their URIs intact and sending that to specific addresses.
 *           Override ERC-721 `approve()`.
 *           Override ERc-721 `setApprovalForAll()`.
 *           Override ERC-721 `tokenURI().`
 *           Override ERC-721 `transferFrom()`.
 *           Override ERC-721 `safeTransferFrom()`.
 *           Override ERC-721 `safeTransferFrom()`.
 *           NFTs cannot be transferred until they're `release()`d.
 *           All functions here except `getOwner()` will be callable only by the `YardPair`.
 */

interface IYardNFTWrapper {
    event Wrapped(uint256 indexed id, address indexed to);
    event Unwrapped(uint256 indexed id);

    /// @dev Lift the transfer and approval restrictions on NFT `id`.
    function release(uint256 id) external;

    /// @dev Mint a new NFT using the metadata for `nft` to `to`.
    function wrap(
        IERC721 nft,
        uint256 id,
        address to
    ) external returns (uint256);

    /// @dev Unwrap `id` by burning `id` and sending underlying NFT back to liquidity provider.
    function unwrap(uint256 id) external returns (bool);

    /// @dev Return the status of the release of NFT `id`.
    function isReleased(uint256 id) external view returns (bool);
}
