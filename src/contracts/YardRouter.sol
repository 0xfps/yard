// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IYardFactory } from "./interfaces/IYardFactory.sol";
import { IYardPair } from "./interfaces/IYardPair.sol";
import { IYardRouter } from "./interfaces/IYardRouter.sol";

import { Ownable, Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
* @title    YardRouter
* @author   fps (@0xfps).
* @dev      YardRouter, this contract is the control center for the Yard protocol.
*           Interactions with specific pairs are done from this contract. Creation and
*           provision of liquidity are also handled here. To top it off, the withdrawals
*           and claims of pool rewards are also initiated here.
*/

abstract contract YardRouter is IYardRouter, Ownable2Step {
    /// @dev Default fee, presumably stable token, $0.3.
    uint32 public constant DEFAULT_FEE = 3e5;
    /// @dev Fee token address.
    address public immutable FEE_TOKEN;
    /// @dev YardFactory interface instance.
    IYardFactory public FACTORY;

    constructor(address feeToken) {
        FEE_TOKEN = feeToken;
    }

    /**
    * @dev      Set factory address and revoke ownership of Router.
    *           Factory can only be set once meaning that on first setting,
    *           FACTORY is address(0). And after setting, ownership is revoked,
    *           ensuring that FACTORY cannot be reset again.
    *
    * @param    factory Address of factory.
    */
    function setFactory(address factory) public onlyOwner {
        if (factory == address(0)) revert("YARD: FACTORY_IS_ZERO_ADDRESS");
        FACTORY = IYardFactory(factory);
        Ownable._transferOwnership(address(0));
    }

    /**
    * @dev      Return the address of a pair of NFTs as stored by the factory.
    * @notice   Factory doesn't have checks for the address(0) case in the getPair()
    *           function. It is recommended that any Router function with calls to the
    *           getPair() function add an extra address(0) check before proceeding.
    *
    * @param    nftA    Address of first NFT.
    * @param    nftB    Address of second NFT.
    *
    * @return   pair    Address of pair contract, can be address 0.
    */
    function getPair(IERC721 nftA, IERC721 nftB) public view returns (address pair) {
        if (FACTORY.getPair(nftA, nftB) == address(0)) revert("YARD: PAIR_INEXISTENT");
        pair = FACTORY.getPair(nftA, nftB);
    }

    /**
    * @dev      Add NFT liquidity to a particular pair pool, returning the ID of the
    *           wrapped NFT to the user.
    *
    * @param    nftA    Address of first NFT.
    * @param    nftB    Address of second NFT.
    * @param    nftIn   Address of NFT, one of the two in the pair.
    * @param    idIn    ID of NFT provided as liquidity.
    * @param    to      Address to receive the wrapped NFT.
    *
    * @return   wId     ID of wrapped NFT.
    */
    function addLiquidity(
        IERC721 nftA,
        IERC721 nftB,
        IERC721 nftIn,
        uint256 idIn,
        address to
    ) public returns (uint256 wId) {
        /// @dev Check validity of liquidity data.
        _checkValidity(nftA, nftB, nftIn);
        wId = _addLiquidity(
            nftA,
            nftB,
            nftIn,
            idIn,
            to
        );
    }

    function addBatchLiquidity(
        IERC721 nftA,
        IERC721 nftB,
        IERC721 nftIn,
        uint256[] memory idsIn,
        address to
    ) public returns (uint256[] memory wIds) {
        if (idsIn.length == 0) revert("YARD: ZER0_NFT_ARRAY");

        /// @dev Check validity of liquidity data.
        _checkValidity(nftA, nftB, nftIn);

        wIds = new uint256[](idsIn.length);

        for (uint256 i; i < idsIn.length; i++) {
            wIds[i] = _addLiquidity(
                nftA,
                nftB,
                nftIn,
                idsIn[i],
                to
            );
        }
    }

    /**
    * @dev Refer to `addLiquidity()`
    */
    function _addLiquidity(
        IERC721 nftA,
        IERC721 nftB,
        IERC721 nftIn,
        uint256 idIn,
        address to
    ) internal returns (uint256 wId) {
        /// @dev Check for `to` being address(0) has been handled by the Pair.
        address pair = getPair(nftA, nftB);
        _transferNFT(nftIn, idIn, msg.sender, pair);

        wId = IYardPair(pair).addLiquidity(
            nftIn,
            idIn,
            msg.sender,
            to
        );

        emit LiquidityAdded(nftIn, idIn);
    }

    /**
    * @notice   Checks the validity of `nftIn` by making sure that it is one of the
    *           two passed addresses. And also, checking to ensure that nftA and nftB
    *           are not the same.
    *
    * @param    nftA    Address of first NFT.
    * @param    nftB    Address of second NFT.
    * @param    nftIn   Address of NFT, one of the two in the pair.
    */
    function _checkValidity(IERC721 nftA, IERC721 nftB, IERC721 nftIn) internal pure {
        if (address(nftA) == address(nftB)) revert("YARD: NFTS_ARE_THE_SAME");
        if (
            (address(nftIn) != address(nftA)) &&
            (address(nftIn) != address(nftB))
        ) revert("YARD: NFT_IN_DOES_NOT_MATCH_EITHER_NFTS");
    }

    /**
    * @notice   Sends nft to factory or pair, depending on call. User must have approved Router to
    *           spend NFT.
    *
    * @param    nft     NFT to send.
    * @param    id      ID of NFT to send.
    * @param    from    Address owning NFT.
    * @param    to      Address of pair or factory.
    */
    function _transferNFT(IERC721 nft, uint256 id, address from, address to) internal {
        nft.safeTransferFrom(from, to, id, "");
    }
}