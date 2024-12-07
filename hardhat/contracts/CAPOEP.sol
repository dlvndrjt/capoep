// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721Pausable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import "./modules/ListingModule.sol";
import "./modules/VotingModule.sol";
import "./modules/CommentsModule.sol";
import "./modules/ReputationModule.sol";
import "./modules/MetadataModule.sol";
import {IListing} from "./interfaces/IListing.sol";

/// @title CAPOEP - Community Attested Proof of Education Protocol
/// @notice Main contract integrating all CAPOEP modules for educational achievement verification
/// @dev Implements ERC721 with module-based functionality for listings, voting, comments, and reputation
/// @custom:security-contact security@capoep.com
contract CAPOEP is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Pausable,
    Ownable,
    ERC721Burnable,
    IListing,
    ListingModule,
    VotingModule,
    CommentsModule,
    ReputationModule
{
    // STATE VARIABLES

    /// @dev Reference to the metadata generation module
    MetadataModule private _metadata;

    /// @dev Counter for generating unique token IDs
    uint256 private _nextTokenId;

    /// @dev Storage for listing vote counts
    mapping(uint256 => ListingTypes.ListingCount) private _listingCounts;

    // CONSTRUCTOR

    /// @notice Initializes the CAPOEP contract with required addresses
    /// @dev Sets up ERC721 metadata and connects to the metadata module
    /// @param initialOwner Address that will own the contract
    /// @param metadataAddress Address of the deployed MetadataModule
    constructor(
        address initialOwner,
        address metadataAddress
    ) ERC721("CAPOEP", "CAPOEP") Ownable(initialOwner) {
        _metadata = MetadataModule(metadataAddress);
    }

    // CORE FUNCTIONS

    /// @notice Mints an NFT from a verified educational listing
    /// @dev Requires listing to have sufficient attestations and be in active state
    /// @param listingId The ID of the listing to mint from
    function mintFromListing(uint256 listingId) external {
        // Get listing data and verify ownership
        IListing.Listing memory listing = getListing(listingId);
        require(msg.sender == listing.creator, "Only creator can mint");

        // Verify listing meets minting requirements
        require(canBeMinted(listingId), "Not enough attestations");
        require(
            listing.state == IListing.ListingState.Active,
            "Listing must be active"
        );

        // Mint new token
        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);

        // Generate and set metadata URI
        string memory uri = _metadata.generateTokenURI(tokenId);
        _setTokenURI(tokenId, uri);

        // Update listing state to minted
        _setListingMinted(listingId);
    }

    // ADMIN FUNCTIONS

    /// @notice Pauses all token transfers and minting
    /// @dev Can only be called by contract owner
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses token transfers and minting
    /// @dev Can only be called by contract owner
    function unpause() public onlyOwner {
        _unpause();
    }

    // OVERRIDE FUNCTIONS

    /// @dev Base URI for computing tokenURI
    function _baseURI() internal pure override returns (string memory) {
        return "https://baseuri";
    }

    /// @dev Required override for ERC721 token transfers
    function _update(
        address to,
        uint256 tokenId,
        address auth
    )
        internal
        override(ERC721, ERC721Enumerable, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    /// @dev Required override for ERC721 balance tracking
    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    /// @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /// @dev ERC165 interface support
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function castVote(
        uint256 listingId,
        bool isAttest,
        string memory comment
    ) public virtual override(VotingModule) {
        // Call parent implementation first
        super.castVote(listingId, isAttest, comment);
        
        // Update counts after vote is cast
        if (isAttest) {
            _listingCounts[listingId].attestCount++;
        } else {
            _listingCounts[listingId].refuteCount++;
        }
    }

    function canBeMinted(uint256 listingId) internal view virtual override(ListingModule) returns (bool) {
        return _listingCounts[listingId].attestCount >= 2;
    }
}
