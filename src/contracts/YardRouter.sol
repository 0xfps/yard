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
    /// @dev Address of YardFactory.
    address public FACTORY;

    constructor(address feeToken) {
        FEE_TOKEN = feeToken;
    }

    /**
    * @dev              Set factory address and revoke ownership of Router.
    *                   Factory can only be set once meaning that on first setting,
    *                   FACTORY is address(0). And after setting, ownership is revoked,
    *                   ensuring that FACTORY cannot be reset again.
    *
    * @param factory    Address of factory.
    */
    function setFactory(address factory) public onlyOwner {
        if (factory == address(0)) revert("YARD: FACTORY_IS_ZERO_ADDRESS");
        FACTORY = factory;
        Ownable._transferOwnership(address(0));
    }
}