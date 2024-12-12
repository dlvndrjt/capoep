// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @title IListing Interface
/// @notice Interface for educational achievement listings in CAPOEP
/// @dev Manages listing lifecycle and versioning
interface IListing {
    // ENUMS

    /// @notice States that a listing can be in throughout its lifecycle
    /// @dev Used to track and control listing permissions and behavior
    enum ListingState {
        Active, // Can receive votes
        Archived, // Superseded by newer version
        Minted // Converted to NFT
    }

    // STRUCTS

    /// @notice Main data structure for educational achievement listings
    /// @dev Contains all relevant information about an educational claim
    struct Listing {
        uint256 id; // Unique identifier
        address creator; // Address that created the listing
        string title; // Title of the achievement
        string details; // Detailed description
        string[] proofs; // Array of proof URIs/links
        string category; // Educational category
        uint256 createdAt; // Creation timestamp
        ListingState state; // Current listing state
        uint256 linkedToId; // ID of newer version (if archived)
        string archiveNote; // Reason for archiving
    }

    // EVENTS

    /// @notice Emitted when a new listing is created
    /// @param id The ID of the new listing
    /// @param creator Address of the listing creator
    event ListingCreated(uint256 indexed id, address indexed creator);

    /// @notice Emitted when a listing's state changes
    /// @param listingId The ID of the listing that changed
    /// @param newState The new state of the listing
    /// @param note Additional information about the state change
    event ListingStateChanged(
        uint256 indexed listingId,
        ListingState indexed newState,
        string note
    );

    // CORE FUNCTIONS

    /// @notice Creates a new educational achievement listing
    /// @dev Emits ListingCreated event upon successful creation
    /// @param title The title of the achievement
    /// @param details Detailed description of the achievement
    /// @param proofs Array of URIs/links proving the achievement
    /// @param category Educational category of the achievement
    /// @return id The unique identifier of the created listing
    function createListing(
        string memory title,
        string memory details,
        string[] memory proofs,
        string memory category
    ) external returns (uint256);

    /// @notice Archives a listing and optionally links to a new version
    /// @dev Can only be called by listing creator when listing is Active
    /// @param listingId The ID of the listing to archive
    /// @param newListingId The ID of the new version (if any)
    /// @param note The reason for archiving
    function archiveListing(
        uint256 listingId,
        uint256 newListingId,
        string memory note
    ) external;

    // VIEW FUNCTIONS

    /// @notice Retrieves a listing by its ID
    /// @param listingId The ID of the listing to retrieve
    /// @return The complete listing struct
    function getListing(
        uint256 listingId
    ) external view returns (Listing memory);

    /// @notice Checks if a listing exists and is in active state
    /// @param listingId The ID of the listing to check
    /// @return bool indicating if listing is active
    function isListingActive(uint256 listingId) external view returns (bool);

    /// @notice Checks if a listing can be edited
    /// @dev A listing can only be edited if it's active and has no votes
    /// @param listingId The ID of the listing to check
    /// @return bool indicating if listing can be edited
    function canEditListing(uint256 listingId) external view returns (bool);

    /// @notice Gets the total number of listings created
    /// @return The total number of listings
    function getTotalListings() external view returns (uint256);

    /// @notice Checks if a listing can be minted
    /// @param listingId The ID of the listing to check
    /// @return bool indicating if listing can be minted
    function canBeMinted(uint256 listingId) external view returns (bool);

    /// @notice Updates listing counts
    /// @param listingId The ID of the listing to update
    /// @param isAttestation Whether the update is for an attestation
    function updateListingCounts(uint256 listingId, bool isAttestation) external;

    /// @notice Sets a listing as minted
    /// @param listingId The ID of the listing to set as minted
    function _setListingMinted(uint256 listingId) external;

    /// @notice Gets the vote counts for a listing
    /// @param listingId The ID of the listing to get vote counts for
    /// @return attestCount The number of attest votes for the listing
    /// @return refuteCount The number of refute votes for the listing
    function getListingCounts(uint256 listingId) 
        external 
        view 
        returns (uint256 attestCount, uint256 refuteCount);

    /// @notice Get the version history of a listing
    /// @param listingId The ID of the listing
    /// @return Array of listing IDs representing the version chain
    function getVersionHistory(uint256 listingId) 
        external 
        view 
        returns (uint256[] memory);

    /// @notice Check if a listing has any votes
    /// @param listingId The ID of the listing
    /// @return True if the listing has any votes
    function hasVotes(uint256 listingId) external view returns (bool);
}
