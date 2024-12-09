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
import {IVoting} from "./interfaces/IVoting.sol";

/// @title CAPOEP - Community Attested Proof of Education Protocol
/// @notice Main contract integrating all CAPOEP modules for educational achievement verification
/// @dev Implements ERC721 with module-based functionality for listings, voting, comments, and reputation
/// @custom:security-contact security@capoep.com
contract CAPOEP is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Pausable, ERC721Burnable, Ownable {
    // STATE VARIABLES

    /// @dev Reference to the metadata generation module
    MetadataModule private _metadata;

    /// @dev Counter for generating unique token IDs
    uint256 private _nextTokenId;

    /// @dev Storage for listing vote counts
    mapping(uint256 => ListingTypes.ListingCount) private _listingCounts;

    // State variables for modules
    ListingModule private _listingModule;
    VotingModule private _votingModule;
    CommentsModule private _commentsModule;
    ReputationModule private _reputationModule;

    // CONSTRUCTOR

    /// @notice Initializes the CAPOEP contract with required addresses
    /// @dev Sets up ERC721 metadata and connects to the metadata module
    /// @param initialOwner Address that will own the contract
    constructor(
        address initialOwner
    ) ERC721("CAPOEP", "CAPOEP") 
      Ownable(initialOwner) {
        // Initialize modules
        _initializeModules(initialOwner);
    }

    /// @dev Internal function to initialize modules
    function _initializeModules(address initialOwner) internal {
        // Initialize modules
        _listingModule = new ListingModule();
        _reputationModule = new ReputationModule(initialOwner);

        _votingModule = new VotingModule(address(_reputationModule));
        _commentsModule = new CommentsModule(address(this), address(_reputationModule));
        _metadata = new MetadataModule();

        // Add authorized updaters using low-level call to bypass onlyOwner
        (bool success1, ) = address(_reputationModule).call(
            abi.encodeWithSignature("addAuthorizedUpdater(address)", address(this))
        );
        (bool success2, ) = address(_reputationModule).call(
            abi.encodeWithSignature("addAuthorizedUpdater(address)", address(_votingModule))
        );
        (bool success3, ) = address(_reputationModule).call(
            abi.encodeWithSignature("addAuthorizedUpdater(address)", initialOwner)
        );
        require(success1 && success2 && success3, "Failed to add authorized updaters");
    }

    // CORE FUNCTIONS

    /// @notice Mints an NFT from a verified educational listing
    /// @dev Requires listing to have sufficient attestations and be in active state
    /// @param listingId The ID of the listing to mint from
    function mintFromListing(uint256 listingId) external {
        // Get listing data and verify ownership
        IListing.Listing memory listing = _listingModule.getListing(listingId);
        require(msg.sender == listing.creator, "Only creator can mint");

        // Verify listing meets minting requirements
        require(_canBeMinted(listingId), "Not enough attestations");
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
        _updateListingMinted(listingId);
    }

    /// @dev Internal method to check if a listing can be minted
    function _canBeMinted(uint256 listingId) internal view returns (bool) {
        return _listingCounts[listingId].attestCount >= 2;
    }

    /// @dev Internal method to update listing minted state
    function _updateListingMinted(uint256 listingId) internal {
        // Assuming there's a way to update listing state in ListingModule
        // You may need to add a method in ListingModule to do this
        // For now, this is a placeholder
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

    /// Cast a vote on a listing
    function castVote(
        uint256 listingId,
        bool isAttest,
        string memory comment
    ) public virtual {
        // Call parent implementation first
        _votingModule.castVote(listingId, isAttest, comment);
        
        // Update counts after vote is cast
        if (isAttest) {
            _listingCounts[listingId].attestCount++;
        } else {
            _listingCounts[listingId].refuteCount++;
        }
    }

    /// Give feedback on a vote
    function giveVoteFeedback(
        uint256 listingId,
        address voter,
        bool isUpvote
    ) external {
        // Use the module's implementation
        _votingModule.giveVoteFeedback(listingId, voter, isUpvote);
    }

    /// @notice Get the ReputationModule address
    /// @return Address of the ReputationModule
    function getReputationModule() external view returns (address) {
        return address(_reputationModule);
    }
}
