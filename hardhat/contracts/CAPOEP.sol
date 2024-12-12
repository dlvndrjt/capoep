// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721Pausable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IListing.sol";
import "./interfaces/IMetadata.sol";
import "./interfaces/IVoting.sol";
import "./interfaces/IComments.sol";
import "./interfaces/IReputation.sol";

/// @title CAPOEP - Community Attested Proof of Education Protocol
/// @notice Main contract handling NFT minting and module coordination
/// @dev Implements ERC721 with multiple extensions
contract CAPOEP is
    ERC721,
    ERC721Burnable,
    ERC721Enumerable,
    ERC721Pausable,
    ERC721URIStorage,
    Ownable
{
    // ERRORS
    error ListingCannotBeMinted();
    error UnauthorizedMint();
    error InvalidModuleAddress();

    // STATE VARIABLES
    /// @dev Counter for token IDs
    uint256 private _nextTokenId;

    /// @dev Module references
    IListing public listingModule;
    IMetadata public metadataModule;
    IVoting public votingModule;
    IComments public commentsModule;
    IReputation public reputationModule;

    // EVENTS
    event ListingMinted(uint256 indexed listingId, uint256 indexed tokenId);
    event ModulesUpdated(
        address listingModule,
        address metadataModule,
        address votingModule,
        address commentsModule,
        address reputationModule
    );

    // CONSTRUCTOR
    constructor(
        address initialOwner,
        address _listingModule,
        address _metadataModule,
        address _votingModule,
        address _commentsModule,
        address _reputationModule
    ) ERC721("CAPOEP", "CAPOEP") Ownable(initialOwner) {
        if (_listingModule == address(0)) revert InvalidModuleAddress();
        if (_metadataModule == address(0)) revert InvalidModuleAddress();
        if (_votingModule == address(0)) revert InvalidModuleAddress();
        if (_commentsModule == address(0)) revert InvalidModuleAddress();
        if (_reputationModule == address(0)) revert InvalidModuleAddress();

        listingModule = IListing(_listingModule);
        metadataModule = IMetadata(_metadataModule);
        votingModule = IVoting(_votingModule);
        commentsModule = IComments(_commentsModule);
        reputationModule = IReputation(_reputationModule);

        emit ModulesUpdated(
            _listingModule,
            _metadataModule,
            _votingModule,
            _commentsModule,
            _reputationModule
        );
    }

    // CORE FUNCTIONS

    /// @notice Create a new listing
    /// @param title The title of the listing
    /// @param details The details of the listing
    /// @param proofs Array of proof URIs
    /// @param category The category of the listing
    function createListing(
        string memory title,
        string memory details,
        string[] memory proofs,
        string memory category
    ) external returns (uint256) {
        return listingModule.createListing(title, details, proofs, category);
    }

    /// @notice Cast a vote on a listing
    /// @param listingId The ID of the listing to vote on
    /// @param isAttest True for attestation, false for refutation
    /// @param comment Required explanation for the vote
    function castVote(
        uint256 listingId,
        bool isAttest,
        string calldata comment
    ) external returns (uint256) {
        return votingModule.castVote(listingId, isAttest, comment);
    }

    /// @notice Mint NFT from a verified listing
    /// @param listingId The ID of the listing to mint from
    function mintFromListing(uint256 listingId) external {
        if (!listingModule.canBeMinted(listingId))
            revert ListingCannotBeMinted();

        IListing.Listing memory listing = listingModule.getListing(listingId);
        if (listing.creator != msg.sender) revert UnauthorizedMint();

        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, metadataModule.generateTokenURI(tokenId));

        listingModule._setListingMinted(listingId);

        emit ListingMinted(listingId, tokenId);
    }

    /// @notice Get all details about a listing
    /// @param listingId The ID of the listing
    /// @return listing The complete listing struct
    /// @return attestCount Number of attestations
    /// @return refuteCount Number of refutations
    /// @return voters Array of addresses that voted on the listing
    function getListingDetails(
        uint256 listingId
    )
        external
        view
        returns (
            IListing.Listing memory listing,
            uint256 attestCount,
            uint256 refuteCount,
            address[] memory voters
        )
    {
        listing = listingModule.getListing(listingId);
        (attestCount, refuteCount) = votingModule.getVoteCount(listingId);
        voters = votingModule.getVoterList(listingId);
    }

    /// @notice Get comments for a listing
    /// @param listingId The ID of the listing
    /// @return Array of comments
    function getListingComments(
        uint256 listingId
    ) external view returns (IComments.Comment[] memory) {
        return commentsModule.getListingComments(listingId);
    }

    /// @notice Get user's reputation
    /// @param user The address to check
    /// @return The user's reputation score
    function getUserReputation(address user) external view returns (int256) {
        return reputationModule.getReputation(user);
    }

    /// @notice Check if a user can vote
    /// @param user The address to check
    /// @return Whether the user can vote
    function canUserVote(address user) external view returns (bool) {
        return reputationModule.getReputation(user) > -10;
    }

    /// @notice Add a comment to a listing
    /// @param listingId The listing ID
    /// @param content The comment content
    /// @param parentId ID of parent comment (0 for top-level)
    function addComment(
        uint256 listingId,
        string calldata content,
        uint256 parentId
    ) external returns (uint256) {
        return commentsModule.addComment(listingId, content, parentId);
    }

    /// @notice Vote on a comment
    /// @param listingId The listing ID
    /// @param commentId The comment ID to vote on
    /// @param isUpvote True for upvote, false for downvote
    function voteOnComment(
        uint256 listingId,
        uint256 commentId,
        bool isUpvote
    ) external {
        commentsModule.voteOnComment(listingId, commentId, isUpvote);
    }

    // ADMIN FUNCTIONS

    /// @notice Update module addresses
    /// @dev Only callable by owner
    function updateModules(
        address _listingModule,
        address _metadataModule,
        address _votingModule,
        address _commentsModule,
        address _reputationModule
    ) external onlyOwner {
        if (_listingModule == address(0)) revert InvalidModuleAddress();
        if (_metadataModule == address(0)) revert InvalidModuleAddress();
        if (_votingModule == address(0)) revert InvalidModuleAddress();
        if (_commentsModule == address(0)) revert InvalidModuleAddress();
        if (_reputationModule == address(0)) revert InvalidModuleAddress();

        listingModule = IListing(_listingModule);
        metadataModule = IMetadata(_metadataModule);
        votingModule = IVoting(_votingModule);
        commentsModule = IComments(_commentsModule);
        reputationModule = IReputation(_reputationModule);

        emit ModulesUpdated(
            _listingModule,
            _metadataModule,
            _votingModule,
            _commentsModule,
            _reputationModule
        );
    }

    // OVERRIDES

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

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

    /// @dev Required override for ERC721URIStorage
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /// @dev Required override for ERC721Enumerable
    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    /// @dev Required override for ERC721Enumerable and ERC721Pausable
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

    /// @notice Pause token transfers
    /// @dev Only callable by owner
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause token transfers
    /// @dev Only callable by owner
    function unpause() external onlyOwner {
        _unpause();
    }

    // Additional required overrides...

    /// @notice Get total supply of minted tokens
    /// @return The total number of tokens minted
    function totalMinted() external view returns (uint256) {
        return _nextTokenId;
    }

    /// @notice Check if a listing exists and can be voted on
    /// @param listingId The listing ID to check
    /// @return True if listing exists and is active
    function canVoteOnListing(uint256 listingId) external view returns (bool) {
        return listingModule.isListingActive(listingId);
    }

    /// @notice Get all tokens owned by an address
    /// @param owner The address to check
    /// @return Array of token IDs owned by the address
    function getTokensOfOwner(
        address owner
    ) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokens = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokens[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokens;
    }

    /// @notice Emergency function to handle stuck tokens
    /// @dev Only callable by owner
    /// @param tokenId The ID of the stuck token
    function emergencyBurn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    /// @notice Emergency pause all modules
    /// @dev Only callable by owner
    function emergencyPause() external onlyOwner {
        _pause();
        // Additional module-specific pause logic if needed
    }
}
