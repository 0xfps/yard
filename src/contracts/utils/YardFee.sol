// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { IYardFee } from "../interfaces/IYardFee.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";

import { YardFeeRange } from "./YardFeeRange.sol";

/**
* @title    YardFee
* @author   fps (@0xfps).
* @dev      An adjustable fee contract for every YardPair guarded by a Timelock.
*           Swaps on Yard were designed to charge a tiny amount of fees as
*           rewards to NFT liquidity providers. Fees are changed by the pool owner
*           and take effect after 1 week. The default fee is 1e5 or 100,000, or,
*           10 cents.
*/

contract YardFee is IYardFee, YardFeeRange, Ownable2Step {
    uint256 internal constant LOCK = 1 weeks;

    uint256 public swapFee;

    uint256 internal newFee;
    uint256 internal startTime;
    bool internal inProgress;

    /// @dev    Emitted when a new fee is queued or updated.
    /// @param  _oldFee `swapFee`.
    /// @param  _newFee `newFee`.
    event FeeChangeQueued(uint256 _oldFee, uint256 _newFee);
    event FeeUpdated(uint256 _oldFee, uint256 _newFee);

    constructor(address _owner_, uint256 _fee) {
        Ownable2Step._transferOwnership(_owner_);
        _updateFee(_fee);
    }

    /**
    * @dev      Updates `swapFee` to `newFee` if there's a change
    *           in progress and time is past limit.
    * @notice   If `inProgress` is true, then:
    *           1. A new `startTime` has been set.
    *           2. A new `newFee` has been set.
    *           `_updateFee()` unsets `inProgress`.
    */
    modifier check() {
        if (inProgress && ((block.timestamp - startTime) >= LOCK)) {
            _updateFee(newFee);
        }

        _;
    }

    /// @dev Update fee if needed and return fee value.
    function getFee() public check returns (uint256) {
        return swapFee;
    }

    /// @dev Allows only contract owner to delete fees.
    function deleteFee() public onlyOwner {
        queueFeeChange(TEN_CENTS);
    }

    /**
    * @dev      Allows the owner to queue a new fee change.
    * @notice   New fees can be queued as long as there is none in
    *           progress. This will set the `startTime` of queue to
    *           be used by the `check()` modifier.
    *
    * @param    _newFee New fee to be set after `LOCK` period.
    */
    function queueFeeChange(uint256 _newFee) public onlyOwner check {
        if (inProgress) revert("YARD: FEE_CHANGE_IN_QUEUE");
        if (!feeIsSettable(_newFee)) revert("YARD: FEE_IS_NOT_0.1_0.3_0.5");
        inProgress = true;
        newFee = _newFee;
        startTime = block.timestamp;

        emit FeeChangeQueued(swapFee, _newFee);
    }

    /**
    * @dev      Updates the fee to a new fee.
    *
    * @param    _newFee New fee.
    */
    function _updateFee(uint256 _newFee) private {
        if (!feeIsSettable(_newFee)) revert("YARD: FEE_IS_NOT_0.1_0.3_0.5");

        inProgress = false;
        uint256 _oldFee = swapFee;
        swapFee = _newFee;

        emit FeeUpdated(_oldFee, _newFee);
    }
}