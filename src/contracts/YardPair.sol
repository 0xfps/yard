// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IYardNFTWrapper } from "./interfaces/IYardNFTWrapper.sol";
import { IYardPair } from "./interfaces/IYardPair.sol";

import { Math } from "./libraries/Math.sol";

import { YardFee } from "./utils/YardFee.sol";

/**
* @title    YardPair
* @author   fps (@0xfps).
* @dev      YardPair, (just like UniswapPair) is a contract that holds all NFTs that are swappable.
*           This can also be called a pool. The idea is that swaps would be instant as long as the
*           ID of the NFT to be swapped to is available in this pair contract. And to top it off,
*           this contract will charge fees on swap, set and adjustable by the pool owner. These
*           fees are accumulated and distributed among liquidity providers according to your pool
*           NFT share.
*/

contract YardPair is IERC721Receiver, IYardPair, YardFee {
    /// @dev Liquidity cannot be withdrawn for a period of 30 days after it has been added.
    uint64 internal constant LIQUIDITY_PERIOD = 30 days;

    /// @dev Total amount of fees claimed from this pool.
    uint256 public totalAmountClaimed;

    /// @dev YardFactory address.
    address internal factory;
    /// @dev YardRouter address.
    address internal router;

    /// @dev Token for paying fees, will be a stable token.
    IERC20 internal feeToken;
    /// @dev YardWrapper contract instance.
    IYardNFTWrapper internal yardWrapper;
    /// @dev YardWrapper contract instance.
    address internal immutable YARD_WRAPPER;

    /// @dev One NFT in the pool.
    IERC721 internal nft0;
    /// @dev Second NFT in pool.
    IERC721 internal nft1;

    /// @dev Number of NFT0 in pool.
    uint256 internal nft0Supply;
    /// @dev Number of NFT1 in pool.
    uint256 internal nft1Supply;
    /// @dev Total supply of NFTs in the pool.
    uint256 internal totalSupply;

    /// @dev An array of all the IDs for NFT0 in the pool.
    uint256[] internal ids0;
    /// @dev An array of all the IDs for NFT1 in the pool.
    uint256[] internal ids1;

    /// @dev    Mapping to identify that a particular id for an NFT of the pair is in the
    ///         respective `ids` array.
    mapping(IERC721 nft => mapping(uint256 id => bool inArray)) internal inArray;
    /// @dev    To save time finding the index of a particular NFT id in the array,
    ///         this mapping stores that data.
    mapping(IERC721 nft => mapping(uint256 id => uint256 index)) internal indexes;

    /// @dev A mapping of each wrapped NFT ID to the underlying NFT address.
    mapping(uint256 wrappedId => IERC721 nft) internal wrappedNFTs;
    /// @dev A mapping of each wrapped NFT ID to the underlying NFT address and NFT ID.
    mapping(uint256 wrappedId => mapping(IERC721 nft => uint256 nftId)) internal underlyingNFTs;

    /// @dev A mapping to show whether an NFT `nft` with ID `id` is still in the pool.
    mapping(IERC721 nft => mapping(uint256 id => bool inPool)) internal inPool;

    /// @dev    A mapping to store how many NFTs a provider has deposited that have not
    ///         been removed by `removeLiquidity`.
    mapping(address provider => uint256 count) internal deposited;
    /// @dev A mapping to store the total number of all the NFTs a provider has deposited in the poo.
    mapping(address provider => uint256 count) internal totalDeposited;

    /// @dev A mapping to store how much a liquidity provider has claimed.
    mapping(address provider => uint256 amount) internal lpRewardAmountClaimed;
    /// @dev A mapping to store the last block timestamp a particular provider added liquidity.
    mapping(address provider => uint256 time) internal lastLPTime;

    /// @dev Reentrancy guard.
    bool internal isLocked;

    /// @dev Reentrancy guard.
    modifier lock() {
        if (isLocked) revert("YARD: TRANSACTION_LOCKED");
        isLocked = true;
        _;
        isLocked = false;
    }

    modifier onlyFactoryOrRouter() {
        if (
            (msg.sender != factory) &&
            (msg.sender != router)
        ) revert("YARD: ONLY_FACTORY_OR_ROUTER");

        _;
    }

    modifier onlyRouter() {
        if ((msg.sender != router)) revert("YARD: ONLY_ROUTER");

        _;
    }

    /**
    * @param nftA           First NFT of pool pair.
    * @param nftB           Second NFT of pool pair.
    * @param _router        Address of YardRouter.
    * @param _pairOwner     Pool owner.
    * @param _fee           Fee amount, it can be 0.1, 0.3 or 0.5.
    * @param _feeToken      Address of fee token, a stable coin.
    * @param _yardWrapper   Address of YardWrapper contract.
    */
    constructor(
        IERC721 nftA,
        IERC721 nftB,
        address _router,
        address _pairOwner,
        uint256 _fee,
        address _feeToken,
        address _yardWrapper
    ) YardFee(_pairOwner, _fee) {
        // @reminder Assert nftA != nftB in YardFactory.
        router = _router;
        feeToken = IERC20(_feeToken);
        YARD_WRAPPER = _yardWrapper;
        yardWrapper = IYardNFTWrapper(_yardWrapper);
        (nft0, nft1) = (nftA > nftB) ? (nftA, nftB) : (nftB, nftA);
    }

    /// @notice Router sends NFTs to Pair, Pair validates ownership and
    ///         finishes up.
    function addLiquidity(
        IERC721 nftIn,
        uint256 idIn,
        address from,
        address to
    )
        external
        onlyRouter
        returns (uint256 wId)
    {
        if ((nftIn != nft0) && (nftIn != nft1)) revert("YARD: NON_POOL_NFT");
        if (nftIn.ownerOf(idIn) != address(this)) revert("YARD: NFT_NOT_RECEIVED");
        if (inPool[nftIn][idIn]) revert("YARD: NFT_IN_POOL");
        if (to == address(0)) revert("YARD: WRAP_TO_ZERO_ADDRESS");

        ++totalSupply;
        ++deposited[from];
        ++totalDeposited[from];

        _updatePoolReserves(nftIn, idIn);

        lastLPTime[from] = block.timestamp;

        wId = yardWrapper.wrap(nftIn, idIn, to);

        wrappedNFTs[wId] = nftIn;
        underlyingNFTs[wId][nftIn] = idIn;

        emit LiquidityAdded(nftIn, idIn);
    }

    function removeLiquidity(
        IERC721 nftOut,
        uint256 idOut,
        uint256 wId,
        address from,
        address to
    )
        external
        lock
        onlyRouter
        returns (uint256 _idOut)
    {
        if ((nftOut != nft0) && (nftOut != nft1)) revert("YARD: NON_POOL_NFT");
        if ((lastLPTime[from] + LIQUIDITY_PERIOD) > block.timestamp)
            revert("YARD: INVALID_LIQUIDITY_REMOVAL_PERIOD");

        if (IERC721(YARD_WRAPPER).ownerOf(wId) != from) revert("YARD: NOT_WRAPPED_NFT_OWNER");

        if (wrappedNFTs[wId] != nftOut) revert("YARD: WRAPPED_TOKEN_MISMATCH");
        if (underlyingNFTs[wId][nftOut] != idOut) revert("YARD: NOT_UNDERLYING_NFT");
        if (to == address(0)) revert("YARD: SENDING_TO_ZERO_ADDRESS");
        if (yardWrapper.isReleased(wId)) revert("YARD: NFT_ALREADY_RELEASED");

        uint256 _reward = _calculateLPRewards(1);

        --deposited[from];
        --totalSupply;

        delete wrappedNFTs[wId];
        delete underlyingNFTs[wId][nftOut];

        totalAmountClaimed += _reward;

        if (inPool[nftOut][idOut]) {
            _balancePoolReserves(nftOut, idOut);

            yardWrapper.unwrap(wId);
            IERC721(YARD_WRAPPER).safeTransferFrom(address(this), to, idOut);
        } else yardWrapper.release(wId);

        feeToken.transfer(to, _reward);

        _idOut = idOut;

        emit LiquidityRemoved(nftOut, idOut);
    }

    function swap(
        IERC721 nftIn,
        uint256 idIn,
        IERC721 nftOut,
        uint256 idOut,
        address to
    )
        external
        lock
        onlyRouter
        returns (uint256 _idOut)
    {
        if (IERC721(nftIn).ownerOf(idIn) != address(this)) revert("YARD: NFT_NOT_RECEIVED");

        (uint256 reserve, ) = getReservesFor(nftOut);

        if (reserve == 0) revert("YARD: ZERO_LIQUIDITY");
        if (!inPool[nftOut][idOut]) revert("YARD: NFT_NOT_IN_POOL");
        if (IERC721(nftOut).ownerOf(idOut) != address(this)) revert("YARD: NFT_NOT_IN_POOL");
        if (to == address(0)) revert("YARD: ZERO_ADDRESS");

        /// @notice Whoever is receiving NFT pays for it.
        feeToken.transferFrom(to, address(this), swapFee);

        _balancePoolReserves(nftOut, idOut);
        _updatePoolReserves(nftIn, idIn);

        IERC721(nftOut).safeTransferFrom(address(this), to, idOut);

        _idOut = idOut;

        emit Swapped(
            nftIn,
            idIn,
            nftOut,
            idOut
        );
    }

    function claimRewards(address lpProvider) external lock returns (uint256 reward) {
        if (lpProvider == address(0)) revert("YARD: CLAIM_BY_ZERO_ADDRESS");
        if (lastLPTime[lpProvider] == 0) revert("YARD: LIQUIDITY_NOT_PROVIDED");
        if ((lastLPTime[lpProvider] + LIQUIDITY_PERIOD) > block.timestamp)
            revert("YARD: INVALID_LIQUIDITY_REMOVAL_PERIOD");

        reward = calculateRewards(lpProvider);
        lpRewardAmountClaimed[lpProvider] += reward;
        totalAmountClaimed += reward;

        feeToken.transfer(lpProvider, reward);

        emit RewardClaimed(lpProvider, reward);
    }

    function getAllReserves() public view returns (uint256, uint256) {
        return (nft0Supply, nft1Supply);
    }

    function getReservesFor(IERC721 nft) public view returns (uint256, uint256[] memory) {
        uint256 supply;
        uint256[] memory supplies;

        /// @notice This is a view function and anyone can call,
        ///         so all must be considered.
        if (nft == nft0) {
            supply = nft0Supply;
            supplies = ids0;
        }

        if (nft == nft1) {
            supply = nft1Supply;
            supplies = ids1;
        }

        return (supply, supplies);
    }

    function calculateRewards(address lpProvider) public view returns (uint256) {
        return _calculateRewards(lpProvider, deposited[lpProvider]);
    }

    /// @dev OpenZeppelin requirement for NFT receptions.
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

    function _balancePoolReserves(IERC721 nftOut, uint256 idOut) internal {
        inPool[nftOut][idOut] = false;

        uint256 index = indexes[nftOut][idOut];

        if (nftOut == nft0) {
            uint256 lastNftIdInArray = ids0[ids0.length - 1];
            ids0 = Math.popArray(ids0, index);
            // Reset the index of the initial last array
            // element to the index of the deleted element.
            indexes[nft0][lastNftIdInArray] = index;
        } else {
            uint256 lastNftIdInArray = ids1[ids1.length - 1];
            ids1 = Math.popArray(ids1, index);
            // Reset the index of the initial last array
            // element to the index of the deleted element.
            indexes[nft1][lastNftIdInArray] = index;
        }

        delete indexes[nftOut][idOut];
        inArray[nftOut][idOut] = false;

        (nftOut == nft0) ? --nft0Supply : --nft1Supply;
    }

    function _updatePoolReserves(IERC721 nftIn, uint256 idIn) internal {
        /// @notice There can only be two NFTs.
        (nftIn == nft0) ? ++nft0Supply : ++nft1Supply;

        inArray[nftIn][idIn] = true;
        inPool[nftIn][idIn] = true;

        if (nftIn == nft0) {
            ids0.push(idIn);
            indexes[nftIn][idIn] = ids0.length - 1;
        } else {
            ids1.push(idIn);
            indexes[nftIn][idIn] = ids1.length - 1;
        }
    }

    function _calculateRewards(address lpProvider, uint256 lpShares)
        internal
        view
        returns (uint256)
    {
        uint256 totalRewards = feeToken.balanceOf(address(this)) + totalAmountClaimed;
        uint256 numerator = lpShares * totalRewards;
        uint256 denominator = totalSupply;

        return (numerator / denominator) - lpRewardAmountClaimed[lpProvider];
    }

    function _calculateLPRewards(uint256 lpShares)
    private
    view
    returns (uint256)
    {
        uint256 totalRewards = feeToken.balanceOf(address(this));

        uint256 numerator = lpShares * totalRewards;
        uint256 denominator = totalSupply;

        return (numerator / denominator);
    }
}