// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

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

abstract contract YardPair is IERC721Receiver, IYardPair {
    uint64 internal constant LIQUIDITY_PERIOD = 30 days;

    address internal factory;
    address internal router;

    IYardToken internal yardToken = IYardToken(address(0x01)); // @reminder Hard code this.
    IYardNFTWrapper internal yardWrapper = IYardNFTWrapper(address(0x02)); // @reminder Hard code this.

    IERC721 internal nft0;
    IERC721 internal nft1;

    uint256 internal nft0Supply;
    uint256 internal nft1Supply;

    uint256[] internal ids0;
    uint256[] internal ids1;

    mapping(IERC721 nft => mapping(uint256 id => bool inArray)) internal inArray;
    mapping(IERC721 nft => mapping(uint256 id => uint256 index)) internal indexes;

    mapping(uint256 wrappedId => IERC721 nft) internal wrappedNFTs;
    mapping(uint256 wrappedId => mapping(IERC721 nft => uint256 nftId)) internal underlyingNFTs;

    mapping(IERC721 nft => mapping(uint256 id => bool inPool)) internal inPool;

    mapping(IERC721 nft => mapping(uint256 id => address provider)) internal depositors;
    mapping(address provider => uint256 count) internal deposited;
    mapping(address provider => uint256 count) internal totalDeposited;

    uint256 internal totalAmountClaimed;

    mapping(address provider => uint256 amount) internal amountClaimed;
    mapping(address provider => uint256 time) internal lastLPRewardClaim;

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
        if (nftIn.ownerOf(idIn) != address(this)) revert("YARD: NFT_NOT_RECEIVED");
        if (inPool[nftIn][idIn]) revert("YARD: NFT_IN_POOL");
        if (to == address(0)) revert("YARD: WRAP_TO_ZERO_ADDRESS");

        /// @notice There can only be two NFTs.
        (nftIn == nft0) ? ++nft0Supply : ++nft1Supply;

        inPool[nftIn][idIn] = true;
        depositors[nftIn][idIn] = from;
        ++deposited[from];
        ++totalDeposited[from];

        inArray[nftIn][idIn] = true;

        if (nftIn == nft0) {
            ids0.push(idIn);
            indexes[nftIn][idIn] = ids0.length - 1;
        } else {
            ids1.push(idIn);
            indexes[nftIn][idIn] = ids1.length - 1;
        }

        if (lastLPRewardClaim[from] == 0) lastLPRewardClaim[from] = block.timestamp;

        wId = yardWrapper.wrap(to);

        wrappedNFTs[wId] = nftIn;
        underlyingNFTs[wId][nftIn] = idIn;
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
}