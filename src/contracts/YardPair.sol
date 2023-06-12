// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IYardNFTWrapper} from "./interfaces/IYardNFTWrapper.sol";
import {IYardPair} from "./interfaces/IYardPair.sol";
import {IYardToken} from "./interfaces/IYardToken.sol";

/**
* @title YardPair
* @author fps (@0xfps).
* @dev YardPair contract.
*/

abstract contract YardPair is IYardPair {
    uint64 internal constant LIQUIDITY_PERIOD = 30 days;

    address internal factory;
    address internal router;

    IYardToken internal yardToken = IYardToken(address(0x01)); // Hard code this.
    IYardNFTWrapper internal yardWrapper = IYardNFTWrapper(address(0x02)); // Hard code this.

    IERC721 internal nft0;
    IERC721 internal nft1;

    uint256 internal nft0Supply;
    uint256 internal nft1Supply;

    uint256[] internal ids0;
    uint256[] internal ids1;

    mapping(uint256 wrappedId => IERC721 nft) internal wrappedNFTs;
    mapping(uint256 wrappedId => mapping(IERC721 nft => uint256 nftId)) internal underlyingNFTs;

    mapping(IERC721 nft => mapping(uint256 id => bool inPool)) internal inPool;

    mapping(IERC721 nft => mapping(uint256 id => address provider)) internal depositors;
    mapping(address provider => uint256 count) internal deposited;
    mapping(address provider => uint256 count) internal totalDeposited;

    uint256 internal totalAmountClaimed;

    mapping(address provider => uint256 amount) internal amountClaimed;
    mapping(address provider => uint128 time) internal lastLPRewardClaim;

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
        /// @reminder Assert nftA != nftB in YardFactory.
        factory = msg.sender;
        router = _router;
        (nft0, nft1) = (nftA > nftB) ? (nftA, nftB) : (nftB, nftA);
    }

    function getAllReserves() external view returns (uint256, uint256) {
        return (nft0Supply, nft1Supply);
    }

    function getReservesFor(IERC721 nft) external view returns (uint256, uint256[] memory) {
        uint256 supply;
        uint256[] memory supplies;

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