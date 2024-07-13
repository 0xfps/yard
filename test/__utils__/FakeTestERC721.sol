// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract FakeTestERC721 is ERC721 {
    uint256 public index;
    uint256[] public mintedTokens;

    constructor() ERC721("Test NFT", "$TNFT") {}

    function getMintedTokensArray() public view returns (uint256[] memory) {
        return mintedTokens;
    }

    function mint(address to, uint256 amount) public {
        for (uint256 i; i < amount; i++) {
            mintedTokens.push(index);
            _mint(to, index);
            ++index;
        }
    }

    function approveAll(address owner, address spender, bool isApproved) public {
        _setApprovalForAll(owner, spender, isApproved);
    }
}