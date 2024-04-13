// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IYardNFTWrapper} from "./interfaces/IYardNFTWrapper.sol";
import {IYardPair} from "./interfaces/IYardPair.sol";
import {IYardToken} from "./interfaces/IYardToken.sol";

import {Math} from "./libraries/Math.sol";

/**
* @title YardPair
* @author fps (@0xfps).
* @dev YardPair contract.
*/

contract YardPair is IERC721Receiver, IYardPair {
    uint64 internal constant LIQUIDITY_PERIOD = 30 days;

    // Goerli addresses, change to taste before deployment. 
    address internal constant YARD_TOKEN = 0x9bC25b28A4144f92b9fa7271dD722Ad4eAB51a25;
    address internal constant YARD_WRAPPER = address(0x02); // @reminder Hard code this.

    address internal factory;
    address internal router;

    IYardToken internal yardToken = IYardToken(YARD_TOKEN);
    IYardNFTWrapper internal yardWrapper = IYardNFTWrapper(YARD_WRAPPER);

    IERC721 internal nft0;
    IERC721 internal nft1;

    uint256 internal nft0Supply;
    uint256 internal nft1Supply;
    uint256 internal totalSupply;

    uint256[] internal ids0;
    uint256[] internal ids1;

    mapping(IERC721 nft => mapping(uint256 id => bool inArray)) internal inArray;
    mapping(IERC721 nft => mapping(uint256 id => uint256 index)) internal indexes;

    mapping(uint256 wrappedId => IERC721 nft) internal wrappedNFTs;
    mapping(uint256 wrappedId => mapping(IERC721 nft => uint256 nftId)) internal underlyingNFTs;

    mapping(IERC721 nft => mapping(uint256 id => bool inPool)) internal inPool;

    mapping(address provider => uint256 count) internal deposited;
    mapping(address provider => uint256 count) internal totalDeposited;

    uint256 internal totalAmountClaimed;

    mapping(address provider => uint256 amount) internal lpRewardAmountClaimed;
    mapping(address provider => uint256 time) internal lastLPTime;

    bool internal isLocked;

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

    constructor(IERC721 nftA, IERC721 nftB, address _router) {
        // @reminder Assert nftA != nftB in YardFactory.
        factory = msg.sender;
        router = _router;
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
        onlyFactoryOrRouter
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

        IERC20(YARD_TOKEN).transfer(to, _reward);

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

        _balancePoolReserves(nftOut, idOut);
        _updatePoolReserves(nftIn, idIn);

        IERC721(nftOut).safeTransferFrom(address(this), to, idOut);

        yardToken.mint();

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

        IERC20(YARD_TOKEN).transfer(lpProvider, reward);

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
        uint256 totalRewards = IERC20(YARD_TOKEN).balanceOf(address(this)) + totalAmountClaimed;
        uint256 numerator = lpShares * totalRewards;
        uint256 denominator = totalSupply;

        return (numerator / denominator) - lpRewardAmountClaimed[lpProvider];
    }

    function _calculateLPRewards(uint256 lpShares)
    private
    view
    returns (uint256)
    {
        uint256 totalRewards = IERC20(YARD_TOKEN).balanceOf(address(this));

        uint256 numerator = lpShares * totalRewards;
        uint256 denominator = totalSupply;

        return (numerator / denominator);
    }
}