// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IYardNFTWrapper } from "../interfaces/IYardNFTWrapper.sol";

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @title   YardNFTWrapper
 * @author  sagetony224 (@sagetony224).
 * @dev     Yard NFT Wrapper contract.
 * @notice  The Yard NFT Wrapper has a singular function of wrapping NFTs
 *          by keeping their URI Metadata intact and minting an NFT with the same
 *          URI to a specific addresses. NFTs minted to addresses are non-transferable
 *          and non-approvable. This is because they represent proofs of liquidity provision
 *          in a particular pair contract. If the owner of a newly minted Yard wrapped NFT
 *          decides to remove liquidity, the underlying NFT that the wrapped entity represents
 *          is sent back to the owner if it still exists in the pool, and the wrapped NFT is
 *          burned. If the underlying NFT is no longer existent in the pool in the expectation that,
 *          it has been swapped and removed from the pool, then the wrapped
 *          NFT is released by calling the release() function, callable only by an approved pair
 *          contract address. The released NFT can then be treated like any normal NFT.
 *
 *          This introduces a flaw to the design of Yard, being that NFTs are always duplicated when wrapped
 *          as a result of liquidity provision, and on the edge case of having the released wrapped NFTs
 *          have pairs with other NFTs, it implies that on provision of liquidity with a
 *          wrapped Yard NFT, the already wrapped Yard NFT will be re-wrapped again, and again
 *          and probably, again, as long as subsequent wrapped NFTs have their own pair.
 */

contract YardNFTWrapper is IYardNFTWrapper, ERC721, Ownable2Step {
    /// @dev NFT ID counter.
    uint256 private nftIndex;
    /// @dev `YardFactory` address.
    address public factory;

    /// @dev A mapping of YardWrapped NFT IDs to their underlying NFT token URIs.
    mapping(uint256 id => string URI) public tokenURIs;
    /// @dev    Mapping of NFT ID to their release status.
    /// @notice NFT IDs that are not released cannot be approved or transferred.
    mapping(uint256 id => bool isReleased) public nftReleasedStatus;
    /// @dev Addresses of pairs that are allowed to wrap NFTs.
    mapping(address pair => bool isAllowed) public allowedPairs;

    /// @dev Only allowed pair addresses are allowed to make this call.
    modifier onlyAllowedPairs() {
        if (!allowedPairs[msg.sender]) revert("YARD: ONLY_ALLOWED_PAIRS");
        _;
    }

    /// @dev Only released NFTs can proceed with this action.
    modifier onlyReleased(uint256 id) {
        if (!nftReleasedStatus[id]) revert("YARD: ONLY_RELEASED");
        _;
    }

    /// @dev Only the factory address can make this call.
    modifier onlyFactory() {
        if (msg.sender != factory) revert("YARD: ONLY_FACTORY");
        _;
    }

    /// @dev Constructor.
    constructor() ERC721("Wrapped Yard NFT", "WyNFT") {}

    /// @notice Factory address can be set once.
    /// @param  _factory Address of new factory address.
    function setFactory(address _factory) public onlyOwner {
        if (factory != address(0)) revert("YARD: FACTORY_SET");
        if (_factory == address(0)) revert("YARD: INVALID_ADDRESS");
        factory = _factory;
    }

    /**
    * @notice   Whenever a new pair is created, the address of the pair is
    *           added to this contract so that that pair can wrap and unwrap
    *           NFTs on the provision and removal of liquidity respectively.
    *           Only the factory address can make this call.
    *
    *           A pair cannot be removed after it has been added.
    *
    * @param    _pair Address of new pair.
    */
    function addPair(address _pair) public onlyFactory {
        if (_pair == address(0)) revert("YARD: INVALID_ADDRESS");
        allowedPairs[_pair] = true;
    }

    /**
    * @notice   During wrap, the token URI of the underlying NFT is set to the
    *           ID of the returned wrap token. In cases where calls would be
    *           made to retrieve the URI of the wrapped token, the URI of the
    *           underlying token is returned.
    *
    * @param    id ID of token.
    *
    * @return   string URI of ID.
    */
    function tokenURI(uint256 id) public view override returns (string memory) {
        return tokenURIs[id];
    }

    /**
    * @notice   The following OpenZeppelin functions override their virtual functions
    *           to allow only released token to have that ability.
    */
    ///////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////
    /////////////////   O V E R R I D E N   F U N C T I O N S   ///////////////////////
    ///////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////
    function approve(address to, uint256 id) public override onlyReleased(id) {
        super.approve(to, id);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override onlyReleased(id) {
        super.transferFrom(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public override onlyReleased(id) {
        super.safeTransferFrom(from, to, id, "");
    }
    ///////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////
    /////////////////   O V E R R I D E N   F U N C T I O N S   ///////////////////////
    ///////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////

    /**
    * @notice   Releases `id`.
    * @dev      Releasing an id makes that id approvable and transferrable.
    *
    * @param    id Token ID.
    */
    function release(uint256 id) public onlyAllowedPairs {
        nftReleasedStatus[id] = true;
    }

    /**
    * @dev      Wrap an NFT.
    *
    * @param    nft NFT Address.
    * @param    id  ID of NFT to wrap.
    * @param    to  Address receiving wrapped NFT.
    *
    * @return   uint256 Wrapped NFT ID, corresponding to `nftIndex`.
    */
    function wrap(
        IERC721 nft,
        uint256 id,
        address to
    ) public onlyAllowedPairs returns (uint256) {
        uint256 _nftIndex = nftIndex;
        nftIndex++;

        tokenURIs[_nftIndex] = ERC721(address(nft)).tokenURI(id);

        _mint(to, _nftIndex);

        emit Wrapped(_nftIndex, to);
        return _nftIndex;
    }

    /**
    * @dev      Unwrap an NFT by burning the NFT. The underlying NFT transfer is
    *           done by the Pair.
    *
    * @param    id ID of NFT to unwrap.
    *
    * @return   bool Unwrapped status.
    */
    function unwrap(uint256 id) public onlyAllowedPairs returns (bool) {
        _burn(id);

        emit Unwrapped(id);
        return true;
    }

    /// @dev Returns the release status of an ID.
    /// @return bool isReleased.
    function isReleased(uint256 id) public view returns (bool) {
        return nftReleasedStatus[id];
    }
}
