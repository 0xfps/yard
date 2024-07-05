// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title   IYardNFTWrapper
 * @author  fps (@0xfps).
 * @dev     Interface for interacting with Yard NFT Wrapper.
 * @notice  Interface for the `YardNFTWrapper` contract.
 */

interface IYardNFTWrapper {
    event Wrapped(uint256 indexed id, address indexed to);
    event Unwrapped(uint256 indexed id);

    /// @dev Lift the transfer and approval restrictions on NFT `id`.
    function release(uint256 id) external;

    /// @dev Mint a new NFT (wrapped) using the metadata for `nft` to `to`.
    function wrap(
        IERC721 nft,
        uint256 id,
        address to
    ) external returns (uint256);

    /// @dev Unwrap `id` by burning `id`.
    function unwrap(uint256 id) external returns (bool);

    /// @dev Return the release status of NFT `id`.
    function isReleased(uint256 id) external view returns (bool);
}
