// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import {IYardToken} from "../interfaces/IYardToken.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
* @title Uchechukwu Anthony Nwachukwu
* @author sagetony224 (@sagetony224).
* @dev A Yard token reward contract.
*/

contract YardReward is IYardToken, ERC20, Ownable2Step {
    uint24 internal _tokenRewardLimit = 1000000;
    uint8 internal _tokenRewardPerSwap = 100;

    address public factory;

    mapping(address => bool) internal _pairsRewardStatus;
    mapping(address => uint256) internal _currentValue;
    mapping(address => uint256) internal _mintingValue;

    /// @dev  Emits the pair address.
    /// @param _pair `pair`.
    event AddPair(address indexed _pair);
    /// @dev  Emits when a token is been reward to pool owner 
    ///       or liquidity provider.
    /// @param _amount `amount`. 
    event Mint(address indexed _pair, uint256 _amount);
    /// @dev  Emits the pair and amount.
    /// @param _amount `amount`. 
    event Burn(address indexed _pair, uint256 _amount);

    modifier onlyFactory() {
        if  (factory != msg.sender)
            revert("YARD: NO_PERMISSION");
        _;
    }

    modifier onlyRewardablePairs() {
        if  (!_pairsRewardStatus[msg.sender])
            revert("YARD: NO_PERMISSION");
        _;
    }

    constructor () ERC20("YARDTOKEN", "YARD"){}

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
        _pairsRewardStatus[_pair] = true;
        if  (_mintingValue[_pair] == 0)
            _mintingValue[_pair] = _tokenRewardPerSwap;

        emit AddPair(_pair);
    }

    /**
    * @dev  Minting the reward to pair.
    * @notice For every 1,000,000 tokens minted to a pair the reward (100 tokens) 
    *         is halved per pair until it get to 3 tokens per swap.
    * @param _pair The pair is a owner of the pool or liquity provider
    *               that receives the tokens.
    */
    function mint(address _pair) public onlyRewardablePairs {
        uint256 _amount = _mintingValue[_pair];
        _currentValue[_pair] += _amount;

        if(_currentValue[_pair] >= _tokenRewardLimit && _mintingValue[_pair] > 3){
            _mintingValue[_pair] /= 2;
            _currentValue[_pair] = 0;
        }
        _mint(_pair, _amount);

        emit Mint(_pair, _amount);

    }

    /**
     * @dev Burns token of a pair.
     * @notice The function burns the token rewards obtained by a owners 
     *         of the pool and liquity providers.
     * @param _amount This is the amount of token to be burned.
     */
    function burn(uint256 _amount) public {
        _currentValue[msg.sender] -= _amount;
        _burn(msg.sender, _amount);

        emit Burn(msg.sender, _amount);

    }
}
