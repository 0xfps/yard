// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IYardFactory } from "./interfaces/IYardFactory.sol";
import { IYardPair } from "./interfaces/IYardPair.sol";

import { Ownable, Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";

import { YardNFTWrapper } from "./utils/YardNFTWrapper.sol";
import { YardPair } from "./YardPair.sol";

/**
* @title    YardFactory
* @author   fps (@0xfps).
* @dev      YardFactory, this contract's only duties are to deploy
*           and keep record of deployed pair addresses.
*/

contract YardFactory is IERC721Receiver, IYardFactory, Ownable2Step {
    /// @dev Router address.
    address public ROUTER;
    /// @dev Address of YardNFTWrapper.
    address public YARD_WRAPPER;
    /// @dev Number of pools created.
    uint256 public poolCount;

    /// @dev NFT pairs mapped to their pool addresses.
    mapping(address nftA => mapping(address nftB => address pair)) internal pairs;

    modifier onlyRouter() {
        if (msg.sender != ROUTER) revert("YARD: ONLY_ROUTER_CAN_CALL");
        _;
    }

    /**
    * @dev      Set router address and revoke ownership of Factory.
    *           Router can only be set once meaning that on first setting,
    *           ROUTER is address(0). And after setting, ownership is revoked,
    *           ensuring that ROUTER cannot be reset again.
    *
    * @param    router Address of router.
    */
    function setRouter(address router) public onlyOwner {
        if (router == address(0)) revert("YARD: ROUTER_IS_ZERO_ADDRESS");
        ROUTER = router;
        Ownable._transferOwnership(address(0));
    }

    /**
    * @dev      YardWrapper address.
    *
    * @param    wrapper Address of wrapper.
    */
    function setWrapper(address wrapper) public onlyOwner {
        if (wrapper == address(0)) revert("YARD: ROUTER_IS_ZERO_ADDRESS");
        YARD_WRAPPER = wrapper;
    }

    /// @dev    Return the address of the `YardPair` contract for [nftA][nftB].
    /// @return pair Address of pair for `nftA` and `nftB`.
    function getPair(IERC721 nftA, IERC721 nftB) public view returns (address pair) {
        pair = pairs[address(nftA)][address(nftB)];
    }

    /**
    * @dev      Pair creations follow a specific order. The NFT(s) to
    *           be used in the pool are approved to the router by the
    *           `_pairOwner`, and sent to the Router. The Router transfers
    *           all NFT(s) to the Factory, which finally sends them to the
    *           Pair.
    *
    * @notice   All checks are done on the Router.
    *
    * @param    nftA            Address of first NFT.
    * @param    idsA            Array of ids for `nftA`.
    * @param    nftB            Address of second NFT.
    * @param    idsB            Array of ids for `nftB`.
    * @param    _pairOwner      Pair creator.
    * @param    _fee            Swap fee for pair.
    * @param    _feeToken       Fee token address for pair, a stable coin.
    * @param    _yardWrapper    Address of YardWrapper.
    * @param    _to             Address to receive wrapped NFTs.
    *
    * @return  pair             Pair Address
    */
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
    ) public onlyRouter returns (address pair) {
        if (address(nftA) == address(nftB)) revert("YARD: NFTS_ARE_THE_SAME");
        pair = getPair(nftA, nftB);

        if (pair != address(0)) {
            _addLiquidityToPair(nftA, idsA, nftB, idsB, _pairOwner, pair, _to);
        } else {
            pair = address(
                new YardPair(
                    nftA,
                    nftB,
                    ROUTER,
                    _pairOwner,
                    _fee,
                    _feeToken,
                    _yardWrapper
                )
            );

            _addLiquidityToPair(nftA, idsA, nftB, idsB, _pairOwner, pair, _to);

            pairs[address(nftA)][address(nftB)] = pair;
            pairs[address(nftB)][address(nftA)] = pair;
            ++poolCount;

            YardNFTWrapper(YARD_WRAPPER).addPair(pair);
            emit PairCreated(nftA, nftB, pair);
        }
    }

    /**
    * @dev      Adds liquidity to `_pair` by first sending NFTs from YardFactory to
    *           YardPair and calling on the `addLiquidity` function.
    *
    * @param    nftA        Address of first NFT.
    * @param    idsA        Array of ids for `nftA`.
    * @param    nftB        Address of second NFT.
    * @param    idsB        Array of ids for `nftB`.
    * @param    _pairOwner  Pair creator.
    * @param    _pair       Pair address.
    * @param    _to         Address to receive wrapped NFTs.
    */
    function _addLiquidityToPair(
        IERC721 nftA,
        uint256[] memory idsA,
        IERC721 nftB,
        uint256[] memory idsB,
        address _pairOwner,
        address _pair,
        address _to
    ) internal {
        if (idsA.length == 0) revert("YARD: ZERO_LENGTH");
        if (idsA.length != idsB.length) revert ("YARD: LENGTH_MISMATCH");

        for (uint256 i; i < idsA.length; i++) {
            nftA.safeTransferFrom(address(this), _pair, idsA[i]);
            nftB.safeTransferFrom(address(this), _pair, idsB[i]);

            IYardPair(_pair).addLiquidity(
                nftA,
                idsA[i],
                _pairOwner,
                _to
            );

            IYardPair(_pair).addLiquidity(
                nftB,
                idsB[i],
                _pairOwner,
                _to
            );
        }
    }

    /// @dev    OpenZeppelin requirement for NFT receptions.
    /// @return bytes4  bytes4(keccak256(
    ///                     onERC721Received(address,address,uint256,bytes)
    ///                 )) => 0x150b7a02.
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return 0x150b7a02;
    }
}

