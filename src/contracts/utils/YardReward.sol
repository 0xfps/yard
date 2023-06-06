// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import {IYardToken} from "../interfaces/IYardToken.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
* @title Uchechukwu Anthony Nwachukwu
* @author sagetony224 (@sagetony224).
* @dev A Yard token reward contract.
*/

contract YardReward is IYardToken, Ownable2Step{
    uint16 constant DEFAULT_TOKEN_LIMIT = 1000000;
    uint16 constant DEFAULT_TOKEN_GIVEN = 100;

    address public immutable factory;

    mapping(address => bool) internal canCall;
    mapping(address => uint256) internal totalValue;
    mapping(address => uint256) internal currentValue;
    mapping(address => uint256) internal mintingValue;

    /**
    * @dev  Emitted when a pair is added or when token reward 
    *       is minted to a pair.
    *  @param addPairEvent `pair`.
    * @param mintEvent `pair, amount`.
    */
    event addPairEvent(address indexed pair);
    event mintEvent(address indexed pair, uint256 indexed amount);

    modifier onlyFactory(){
        require(factory == msg.sender, "No Permission");
        _;
    }

    modifier onlyCanCall(){
        require(canCall[msg.sender] == true, "No Permission");
        _;
    }
    modifier validAddress(address _validAddress){
        require(_validAddress != address(0), "Invalid Address");
    }

    /**
    * @dev  Adding a pair callable by the factory.
    * @param _factory Factory.
    */
    function setFactory(address _factory) public onlyOwner validAddress(_factory){
        factory = _factory;
    }

    /**
    * @dev  Adding a pair callable by the factory.
    * @param _pair Pair.
    */
    function addPair(address _pair) public onlyFactory validAddress(_pair){
        canCall[_pair] = true;
        if(mintingValue[_pair] = 0){
            mintingValue[_pair] = DEFAULT_TOKEN_GIVEN;
        }

        emit addPairEvent(_pair);
    }

    /**
    * @dev  Minting the reward to pair.
    * @notice For every 1,000,000 tokens minted to a pair the reward (100 tokens) 
    *         is halved per pair until it get to 3 tokens per swap.
    * @param _pair Pair.
    */
    function mint(address _pair) public onlyCanCall{
        uint256 _amt = mintingValue[_pair];
        currentValue[_pair] += _amt;
        totalValue[_pair] += _amt;

        if(currentValue[_pair] >= DEFAULT_TOKEN_LIMIT && mintingValue[_pair] <= 3){
            mintingValue[_pair] /= 2;
            currentValue[_pair] = 0;
        }
        super.mint(_pair, _amt);

        emit mintEvent(_pair, _amt);

    }
}
