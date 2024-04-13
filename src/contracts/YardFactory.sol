// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IYardFactory} from "./interfaces/IYardFactory.sol";

import {YardPair} from "./YardPair.sol";

/**
* @title YardFactory
* @author fps (@0xfps).
* @dev YardFactory contract.
*/

contract YardFactory is IYardFactory {
    uint32 internal constant TEN_CENTS = 100000;
    uint32 internal constant THIRTY_CENTS = 300000;
    uint32 internal constant FIFTY_CENTS = 500000;

    address public immutable YARD_WRAPPER;
    address public immutable FEE_TOKEN; // USDC.

    address public YARD_ROUTER;

    bool public initialized;
    uint256 public pairCount;
    address[] public allPairs;
    address public factoryDeployer;

    mapping(address nftA => mapping(address nftB => address pair)) public pairs;
    mapping(address pair => address[2]) public nftsAtPair;

    constructor(address _feeToken, address _yardWrapper) {
        FEE_TOKEN = _feeToken;
        YARD_WRAPPER = _yardWrapper;
        factoryDeployer = msg.sender;
    }

    function setRouter(address _router) public {
        if (msg.sender != factoryDeployer) revert("YARD: NOT_OWNER!");
        if (initialized) revert ("YARD: FACTORY_INITIALIZED!");

        YARD_ROUTER = _router;
        initialized = true;
    }

    function createPair(
        IERC721 nftA,
        uint256[] memory idsA,
        IERC721 nftB,
        uint256[] memory idsB,
        address creator,
        uint32 fee
    ) external returns (address pair) {
        if (msg.sender != YARD_ROUTER) revert("YARD: ONLY_ROUTER!");

        address _nftA = address(nftA);
        address _nftB = address(nftB);

        if ((_nftA == address(0))|| (_nftB == address(0))) revert("YARD: ZERO_ADDRESS!");
        if (nftA == nftB) revert("YARD: NFTS_ARE_THE_SAME!");
        if (idsA.length != idsB.length) revert("YARD: LENGTH_MISMATCH!");

        if ((fee != TEN_CENTS) || (fee != THIRTY_CENTS) || (fee != FIFTY_CENTS)) revert("YARD: INVALID_FEE_SELECTION!");

        pair = address(
            new YardPair(
                nftA,
                nftB,
                YARD_ROUTER,
                YARD_WRAPPER,
                creator,
                FEE_TOKEN,
                fee
            )
        );

        pairs[_nftA][_nftB] = pair;
        allPairs.push(pair);
        nftsAtPair[pair] = [_nftA, _nftB];

        emit PairCreated(nftA, nftB, pair, creator);
    }

    function getPair(address nftA, address nftB) public view returns (address) {
        if (pairs[nftA][nftB] == address(0)) revert("YARD: NOT_PAIR!");
        return pairs[nftA][nftB];
    }

    function getNFTsAtPair(address pair) external view returns (address, address) {
        return (nftsAtPair[pair][0], nftsAtPair[pair][1]);
    }
}