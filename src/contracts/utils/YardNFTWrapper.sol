// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IYardNFTWrapper} from "../interfaces/IYardNFTWrapper.sol";

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @title YardNFTWrapper
 * @author sagetony224 (@sagetony224).
 * @dev A Yard NFT Wrapper contract.
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

contract YardNFTWrapper is IYardNFTWrapper, ERC721, Ownable2Step {
    address internal yardTrash;
    uint256 private nftIndex;
    address public factory;

    mapping(uint256 => string) public tokenURIs;
    mapping(uint256 => bool) public nftReleasedStatus;
    mapping(address => bool) public allowedPairs;

    modifier onlyAllowedPairs() {
        if (!allowedPairs[msg.sender]) revert("YARD: ONLY_ALLOWED_PAIRS");
        _;
    }

    modifier onlyReleased(uint256 id) {
        if (!nftReleasedStatus[id]) revert("YARD: ONLY_RELEASED");
        _;
    }

    modifier onlyFactory() {
        if (msg.sender != factory) revert("YARD: ONLY_FACTORY");
        _;
    }

    constructor() ERC721("Wrapped Yard NFT", "WyNFT") {}

    function setFactory(address _factory) public onlyOwner {
        if (_factory == address(0)) revert("YARD: INVALID_ADDRESS");
        factory = _factory;
    }

    function addPair(address _pair) public onlyFactory {
        if (_pair == address(0)) revert("YARD: INVALID_ADDRESS");
        allowedPairs[_pair] = true;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return tokenURIs[id];
    }

    function approve(address to, uint256 id) public override onlyReleased(id) {
        super.approve(to, id);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override {
        super._setApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override onlyReleased(id) {
        super.transferFrom(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public override onlyReleased(id) {
        super.safeTransferFrom(from, to, id, "");
    }

    function release(uint256 id) public onlyAllowedPairs {
        nftReleasedStatus[id] = true;
    }

    function wrap(
        IERC721 nft,
        uint256 id,
        address to
    ) public onlyAllowedPairs returns (uint256) {
        uint256 _nftIndex = nftIndex;
        nftIndex++;

        tokenURIs[_nftIndex] = ERC721(address(nft)).tokenURI(id);

        _mint(to, _nftIndex);

        emit Wrapped(_nftIndex, to);
        return _nftIndex;
    }

    function unwrap(uint256 id) public onlyAllowedPairs returns (bool) {
        _burn(id);

        emit Unwrapped(id);
        return true;
    }

    function isReleased(uint256 id) public view returns (bool) {
        return nftReleasedStatus[id];
    }
}
