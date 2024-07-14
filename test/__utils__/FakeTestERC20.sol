// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FakeTestERC20 is ERC20 {
    constructor() ERC20("Stable Fee Token", "$SFT") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}