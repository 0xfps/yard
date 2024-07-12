// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IYardFactory } from "./interfaces/IYardFactory.sol";
import { IYardPair } from "./interfaces/IYardPair.sol";
import { IYardRouter } from "./interfaces/IYardRouter.sol";

import { Math } from "./libraries/Math.sol";

import { Ownable, Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";

import { YardFeeRange } from "./utils/YardFeeRange.sol";

/**
* @title    YardRouter
* @author   fps (@0xfps).
* @dev      YardRouter, this contract is the interaction center for Yard. Interactions
*           between pools are done from the Router. Creation of new pools is also done
*           from here.
*
*           To swap between two pools, a user passed a `path`. A `path` is an array of
*           NFT addresses that are paired in twos recursively, meaning that, for a path
*           we will assume to be [A, B, C, D, E, F, G, H], across different NFT pairs,
*           the swap will be carried out across `<array>.length - 1` pools. To list them,
*           A-B, B-C, C-D, D-E, E-F, F-G, G-H.
*/

contract YardRouter is IERC721Receiver, IYardRouter, YardFeeRange, Ownable2Step {
    /// @dev Default fee, presumably stable token, $0.1.
    uint32 public constant DEFAULT_FEE = TEN_CENTS;
    /// @dev Fee token address.
    address public immutable FEE_TOKEN;
    /// @dev YardWrapper contract address.
    address public immutable YARD_WRAPPER;
    /// @dev YardFactory interface instance.
    IYardFactory public FACTORY;

    /// @dev Reentrancy guard.
    bool internal isLocked;

    /// @dev Reentrancy guard.
    modifier lock() {
        if (isLocked) revert("YARD: TRANSACTION_LOCKED");
        isLocked = true;
        _;
        isLocked = false;
    }

    constructor(address feeToken, address yardWrapper) {
        FEE_TOKEN = feeToken;
        YARD_WRAPPER = yardWrapper;
    }

    /**
    * @dev      Set factory and YardWrapper address and revoke ownership of Router.
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

    /**
    * @dev      Add liquidity for a bunch of NFTs to a particular pair pool,
    *           returning the ID of all the wrapped NFTs sent to the user.
    *
    * @param    nftA    Address of first NFT.
    * @param    nftB    Address of second NFT.
    * @param    nftIn   Address of NFT, one of the two in the pair.
    * @param    idsIn   IDs of NFT provided as liquidity.
    * @param    to      Address to receive the wrapped NFT.
    *
    * @return   wIds    IDs of wrapped NFT.
    */
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

        emit BatchLiquidityAdded(nftIn, idsIn);
    }

    /**
    * @dev      Remove NFT liquidity from a particular pair pool, returning the ID of the
    *           NFT removed.
    *
    * @param    nftA    Address of first NFT.
    * @param    nftB    Address of second NFT.
    * @param    nftOut  Address of NFT, one of the two in the pair.
    * @param    idOut   ID of NFT taken.
    * @param    to      Address to receive the withdrawn NFT.
    *
    * @return   _idOut  ID of removed NFT.
    */
    function removeLiquidity(
        IERC721 nftA,
        IERC721 nftB,
        IERC721 nftOut,
        uint256 idOut,
        uint256 wId,
        address to
    ) public lock returns (uint256 _idOut) {
        /// @dev Check validity of liquidity data.
        _checkValidity(nftA, nftB, nftOut);

        _idOut = _removeLiquidity(
            nftA,
            nftB,
            nftOut,
            idOut,
            wId,
            to
        );

        emit LiquidityRemoved(nftOut, idOut);
    }

    /**
    * @dev      Remove liquidity for a group of NFTs from a particular pair pool, returning the IDs of the
    *           NFTs removed.
    *
    * @param    nftA    Address of first NFT.
    * @param    nftB    Address of second NFT.
    * @param    nftOut  Address of NFT, one of the two in the pair.
    * @param    idsOut  IDs of NFTs taken.
    * @param    to      Address to receive the withdrawn NFTs.
    *
    * @return   _idsOut IDs of removed NFTs.
    */
    function removeBatchLiquidity(
        IERC721 nftA,
        IERC721 nftB,
        IERC721 nftOut,
        uint256[] memory idsOut,
        uint256[] memory wIds,
        address to
    ) public lock returns (uint256[] memory _idsOut) {
        /// @dev Check validity of liquidity data.
        _checkValidity(nftA, nftB, nftOut);

        if (idsOut.length == 0) revert("YARD: ZERO_LENGTH");
        if (idsOut.length != wIds.length) revert("YARD: LENGTH_MISMATCH");

        _idsOut = new uint256[](_idsOut.length);

        for (uint256 i; i < idsOut.length; i++) {
            _idsOut[i] = _removeLiquidity(
                nftA,
                nftB,
                nftOut,
                idsOut[i],
                wIds[i],
                to
            );
        }

        emit BatchLiquidityRemoved(nftOut, idsOut);
    }

    /**
    * @dev      Call to Factory to create pair.
    *
    * @param    nftA    Address of first NFT.
    * @param    idsA    Array of ids for `nftA`.
    * @param    nftB    Address of second NFT.
    * @param    idsB    Array of ids for `nftB`.
    * @param    fee     Swap fee for pair.
    * @param    to      Address to receive wrapped NFTs.
    *
    * @return  pair     Pair Address
    */
    function createPair(
        IERC721 nftA,
        uint256[] memory idsA,
        IERC721 nftB,
        uint256[] memory idsB,
        uint256 fee,
        address to
    ) public returns (address pair) {
        if (
            (address(nftA) == address(0)) ||
            (address(nftB) == address(0))
        ) revert("YARD: ZERO_ADDRESS_NFT");

        if (idsA.length == 0) revert("YARD: ZERO_LENGTH");
        if (idsA.length != idsB.length) revert ("YARD: LENGTH_MISMATCH");
        if (to == address(0)) revert("YARD: ZERO_TO_ADDRESS");

        if (!feeIsSettable(fee)) revert("YARD: FEE_NOT_SETTABLE_CHOOSE_EITHER_0.1_0.3_0.5_*1E6");

        for (uint256 i; i < idsA.length; i++) {
            _transferNFT(nftA, idsA[i], msg.sender, address(FACTORY));
            _transferNFT(nftB, idsB[i], msg.sender, address(FACTORY));
        }

        pair = FACTORY.createPair(
            nftA,
            idsA,
            nftB,
            idsB,
            msg.sender,
            fee,
            FEE_TOKEN,
            YARD_WRAPPER,
            to
        );
    }

    /**
    * @notice   Swap one NFT for another NFT in the same pool.
    *           There are no cross pool swaps here. This function will only
    *           handle the swaps for two NFTs. `path` would be an array of
    *           just two elements.
    *           The first element is the NFT that the user wishes to put into
    *           the pool, and the second is the NFT they want to take out of the pool.
    *
    * @param    path    Array of NFT pools to traverse.
    * @param    idIn    ID of NFT to go into the pool.
    * @param    idOut   ID of NFT to leave the pool.
    * @param    to      Address to receive NFT.
    *
    * @return   _idOut  ID of NFT to leave the pool.
    */
    function swapNFTForExactNFT(
        IERC721[] memory path,
        uint256 idIn,
        uint256 idOut,
        address to
    ) public lock returns (uint256 _idOut) {
        if (path.length != 2) revert("YARD: PATH_MUST_BE_TWO");

        /// @dev Direct swap.
        (bool pairExists, address pair) = _pairExists(path[0], path[1]);
        if (!pairExists) revert("YARD: PAIR_INEXISTENT");

        _idOut = _swap(
            pair,
            path[0],
            idIn,
            path[1],
            idOut,
            to
        );
    }

    /**
    * @dev      Swap some NFTs for another set of  NFTs across specified pools.
    *           One NFT is swapped in to the first pair and the output is swapped
    *           into the second pair. The process continues until the last NFT is
    *           swapped out. Then sent to `to`.
    *
    * @param    path    NFT path to follow.
    * @param    idIn    NFTs to send in to the pair.
    * @param    idsOut  NFTs to send in to the router.
    * @param    to      Address to receive the final NFT.
    *
    * @return   uint256 Final NFT ID.
    */
    function swapExactNFTsForExactNFTsAcrossPools(
        IERC721[] memory path,
        uint256 idIn,
        uint256[] memory idsOut,
        address to
    ) public lock returns (uint256) {
        if (path.length < 2) revert("YARD: PATH_MUST_BE_AT_LEAST_TWO");
        if (idsOut.length != (path.length - 1)) revert("YARD: INVALID_SWAP_LENGTH");
        if (to == address(0)) revert("YARD: ZERO_RECIPIENT_ADDRESS");

        uint256 idOut;

        for (uint256 i; i < path.length - 1; i++) {
            IERC721[] memory _path = new IERC721[](2);
            _path[0] = path[i];
            _path[1] = path[i + 1];

            if (i == 0) {
                /// Send first NFT from user to pair.
                idOut = swapNFTForExactNFT(_path, idIn, idsOut[0], address(this));
            } else {
                (bool pairExists, address pair) = _pairExists(_path[0], _path[1]);
                if (!pairExists) revert("YARD: PAIR_INEXISTENT");

                _transferNFT(path[i], idsOut[i], address(this), pair);
                idOut = IYardPair(pair).swap(
                    path[i],
                    idsOut[i],
                    path[i + 1],
                    idsOut[i + 1],
                    msg.sender,
                    address(this)
                );

                emit Swapped(path[i], idsOut[i], path[i + 1], idOut);
            }
        }

        IERC721(path[path.length - 1]).safeTransferFrom(address(this), to, idOut);

        return idOut;
    }

    /**
    * @notice   Swap a group NFT for another group NFT in the same pool.
    *           There are no cross pool swaps here. This function will only
    *           handle the swaps for two NFTs. `path` would be an array of
    *           just two elements.
    *           The first element is the NFT that the user wishes to put into
    *           the pool, and the second is the NFT they want to take out of the pool.
    *
    * @param    path    Array of NFT pools to traverse.
    * @param    idsIn   IDs of NFT to go into the pool.
    * @param    idsOut  IDs of NFT to leave the pool.
    * @param    to      Address to receive NFT.
    *
    * @return   _idsOut IDs of NFT to leave the pool.
    */
    function swapBatchNFTsForExactNFTs(
        IERC721[] memory path,
        uint256[] memory idsIn,
        uint256[] memory idsOut,
        address to
    ) public lock returns (uint256[] memory _idsOut) {
        if (path.length != 2) revert("YARD: INVALID_PATH_LENGTH");
        if (idsIn.length < (path.length - 1)) revert("YARD: INVALID_SWAP_LENGTH");
        if (idsIn.length != idsOut.length) revert("YARD: LENGTH_MISMATCH");

        _idsOut = new uint256[](idsIn.length);

        for (uint256 i; i < idsIn.length - 1; i++) {
            _idsOut[i] = swapNFTForExactNFT(path, idsIn[i], idsOut[i], to);
        }

        emit BatchSwapped(
            path,
            idsIn,
            idsOut
        );
    }

    /**
    * @dev      Swaps an NFT for a random NFT in a pool.
    *
    * @param    path    NFT path to follow.
    * @param    idIn    NFTs to send in to the pair.
    * @param    to      Address to receive each output NFT.
    *
    * @return   idOut   Array of IDs received from the pool.
    */
    function swapNFTForArbitraryNFT(
        IERC721[] memory path,
        uint256 idIn,
        address to
    ) public lock returns (uint256 idOut) {
        if (path.length != 2) revert("YARD: PATH_MUST_BE_TWO");

        idOut = precalculateOutputNFT(path[0], path[1], path[0]);
        idOut = swapNFTForExactNFT(path, idIn, idOut, to);
    }

    /**
    * @dev      Swaps a couple of NFTs for random NFTs in a pool.
    *
    * @param    path    NFT path to follow.
    * @param    idsIn   Array of NFTs to send in to the pair.
    * @param    to      Address to receive each output NFT.
    *
    * @return   idsOut  Array of IDs received from the pool.
    */
    function swapBatchNFTsForArbitraryNFTs(
        IERC721[] memory path,
        uint256[] memory idsIn,
        address to
    ) public lock returns (uint256[] memory idsOut) {
        if (path.length != 2) revert("YARD: INVALID_PATH_LENGTH");
        if (idsIn.length < (path.length - 1)) revert("YARD: INVALID_SWAP_LENGTH");

        idsOut = new uint256[](idsIn.length);

        for (uint256 i; i < idsIn.length - 1; i++) {
            uint256 idOut = precalculateOutputNFT(path[0], path[1], path[1]);
            idsOut[i] = swapNFTForExactNFT(path, idsIn[i], idOut, to);
        }
    }

    /**
    * @dev      Take all claimable rewards for `msg.sender`.
    *
    * @param    nftA    Address of one NFT in the pair.
    * @param    nftB    Address of pair NFT.
    *
    * @return   uint256 Amount withdrawn.
    */
    function takeRewards(
        IERC721 nftA,
        IERC721 nftB
    ) public returns (uint256) {
        (bool pairExists, address pair) = _pairExists(nftA, nftB);
        if (!pairExists) revert("YARD: PAIR_INEXISTENT");

        return IYardPair(pair).claimRewards(msg.sender);
    }

    /**
    * @dev      Return the supply of nftA and nftB in the pool respectively.
    *
    * @param    nftA                Address of one NFT in the pair.
    * @param    nftB                Address of pair NFT.
    *
    * @return   uint256, uint256    Supply of NFT A and NFT B in the pool.
    */
    function viewAllReserves(IERC721 nftA, IERC721 nftB)
        public
        view
        returns (uint256, uint256)
    {
        (bool pairExists, address pair) = _pairExists(nftA, nftB);
        if (!pairExists) revert("YARD: PAIR_INEXISTENT");

        return IYardPair(pair).getAllReserves();
    }

    /**
    * @dev      Return how much rewards `lpProvider` is entitled to.
    *
    * @param    nftA        Address of one NFT in the pair.
    * @param    nftB        Address of pair NFT.
    * @param    lpProvider  Address of liquidity provider.
    *
    * @return   uint256     Amount of stable token receivable by lpProvider.
    */
    function getRewards(
        IERC721 nftA,
        IERC721 nftB,
        address lpProvider
    ) public view returns (uint256) {
        (bool pairExists, address pair) = _pairExists(nftA, nftB);
        if (!pairExists) revert("YARD: PAIR_INEXISTENT");

        return IYardPair(pair).calculateRewards(lpProvider);
    }

    /**
    * @dev      Using the random() function in the Math library, this function will
    *           return the index of an NFT that lies between 0 to the number one short
    *           of the total supply of the nft to be taken out.
    *
    * @param    nftA    Address of one NFT in the pair.
    * @param    nftB    Address of pair NFT.
    * @param    nftIn   Address of input NFT.
    *
    * @return   idOut   ID of nftOut the user will receive.
    */
    function precalculateOutputNFT(
        IERC721 nftA,
        IERC721 nftB,
        IERC721 nftIn
    ) public view returns (uint256 idOut) {
        _checkValidity(nftA, nftB, nftIn);
        IERC721 nftOut = nftIn == nftA ? nftB : nftA;
        (bool pairExists, address pair) = _pairExists(nftA, nftB);
        if (!pairExists) revert("YARD: PAIR_INEXISTENT");

        /// @dev supply == supplyArray.length
        (uint256 supply, uint256[] memory supplyArray) = IYardPair(pair).getReservesFor(nftOut);
        if (supply == 0) revert("YARD: ZERO_LIQUIDITY_FOR_OUTPUT_NFT");
        uint256 randomIndex = Math.random(supply);
        return supplyArray[randomIndex];
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
        /// @dev Check for `to` being address(0) has been handled in the getPair().
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
    * @dev Refer to `removeLiquidity()`
    */
    function _removeLiquidity(
        IERC721 nftA,
        IERC721 nftB,
        IERC721 nftOut,
        uint256 idOut,
        uint256 wId,
        address to
    ) internal returns (uint256 _idOut) {
        /// @dev Check for `to` being address(0) has been handled by the Pair.
        address pair = getPair(nftA, nftB);

        _idOut = IYardPair(pair).removeLiquidity(
            nftOut,
            idOut,
            wId,
            msg.sender,
            to
        );

        emit LiquidityRemoved(nftOut, _idOut);
    }

    /**
    * @dev Underlying swap functionality.
    */
    function _swap(
        address pair,
        IERC721 nftIn,
        uint256 idIn,
        IERC721 nftOut,
        uint256 idOut,
        address to
    ) internal returns (uint256 _idOut) {
        _transferNFT(nftIn, idIn, msg.sender, pair);

        _idOut = IYardPair(pair).swap(
            nftIn,
            idIn,
            nftOut,
            idOut,
            msg.sender,
            to
        );

        emit Swapped(nftIn, idIn, nftOut, idOut);
    }

    /**
    * @notice   Returns true and the address of a pair if it exists in the Factory, and
    *           false and address(0) if it doesn't.
    *
    * @param    nftA Address of first NFT.
    * @param    nftB Address of second NFT.
    *
    * @return   (bool, address) Existence truthiness and pair address or address(0).
    */
    function _pairExists(IERC721 nftA, IERC721 nftB) internal view returns (bool, address) {
        address pair = getPair(nftA, nftB);
        return pair != address(0) ? (true, pair) : (false, address(0));
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