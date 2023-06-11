// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import {IYardToken} from "../interfaces/IYardToken.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
* @title Uchechukwu Anthony Nwachukwu
* @author sagetony224 (@sagetony224).
* @dev A Yard token reward contract.
*/

contract YardReward is IYardToken, Ownable2Step {
    uint8 internal tokenRewardLimit = 1000000;
    uint8 internal tokenRewardPerSwap = 100;

    address public immutable factory;

    mapping(address => bool) internal pairsRewardStatus;
    mapping(address => uint256) internal pairsTotalValue;
    mapping(address => uint256) internal currentValue;
    mapping(address => uint256) internal mintingValue;

    /**
    * @dev  Emitted when a pair is added or when token reward 
    *       is minted to a pair. Emit when a token id burned.
    * @param pair `_pair`.
    * @param amount `_amt`. 
    */
    event addPairEvent(address indexed pair);
    event mintEvent(address indexed pair, uint256 indexed amount);
    event burnEvent(address indexed pair, uint256 indexed amount);

    modifier onlyFactory() {
        if  (factory != msg.sender)
            revert("YARD: NO_PERMISSION");
        _;
    }

    modifier onlyRewardablePairs() {
        if  (!pairsRewardStatus[msg.sender])
            revert("YARD: NO_PERMISSION");
        _;
    }

    /**
    * @dev  Setting a factory callable by only the owner.
    * @param _factory The address will be set to factory.
    */
    function setFactory(address _factory) public onlyOwner {
        factory = _factory;
    }

    /**
    * @dev  Adding a pair callable by the factory.
    * @param _pair Pair.
    */
    function addPair(address _pair) public onlyFactory {
        pairsRewardStatus[_pair] = true;
        if  (mintingValue[_pair] = 0)
            mintingValue[_pair] = tokenRewardPerSwap;

        emit addPairEvent(_pair);
    }

    /**
    * @dev  Minting the reward to pair.
    * @notice For every 1,000,000 tokens minted to a pair the reward (100 tokens) 
    *         is halved per pair until it get to 3 tokens per swap.
    * @param _pair is the address to received the tokens.
    */
    function mint(address _pair) public onlyRewardablePairs {
        uint256 _amt = mintingValue[_pair];
        currentValue[_pair] += _amt;
        pairsTotalValue[_pair] += _amt;

        if(currentValue[_pair] >= tokenRewardLimit && mintingValue[_pair] > 3){
            mintingValue[_pair] /= 2;
            currentValue[_pair] = 0;
        }
        super._mint(_pair, _amt);

        emit mintEvent(_pair, _amt);

    }

    /**
     * @dev Burns token of a pair.
     * @notice The function burns the tokens obtained by a pair.
     * @param _amount This is the amount of token to be burned.
     */
    function burn(uint256 _amount) public {
        if(pairsTotalValue[msg.sender] < _amount)
            revert("YARD: Insufficent Token");
        
        currentValue[msg.sender] -= _amount;
        pairsTotalValue[msg.sender] -= amount;

        super._burn(msg.sender, _amount);

        emit burnEvent(msg.sender, _amount);

    }
}
