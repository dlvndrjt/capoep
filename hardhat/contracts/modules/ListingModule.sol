// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../interfaces/IListing.sol";
import "../interfaces/IErrors.sol";
import "../libraries/ListingTypes.sol";

/// @title ListingModule
/// @notice Implements educational achievement listing management for CAPOEP
/// @dev Handles listing lifecycle, versioning, and state management
contract ListingModule is IListing, IErrors {
    // CUSTOM ERRORS
    error InvalidListingVersion();
    error ListingAlreadyMinted();
    error InvalidListingId();
    error InvalidListingState();
    error EmptyTitle();
    error EmptyDetails();
    error NoProofs();
    error InvalidLinkedListing();
    error InsufficientAttestations();

    // CONSTANTS
    /// @dev Minimum number of attestations required for minting
    uint256 public constant MIN_ATTESTATIONS_FOR_MINT = 2;

    // STATE VARIABLES

    /// @dev Counter for generating unique listing IDs
    uint256 private _nextListingId;

    /// @dev Primary storage for all listings
    mapping(uint256 => Listing) private _listings;

    /// @dev Storage for listing vote counts
    mapping(uint256 => ListingTypes.ListingCount) private _listingCounts;

    /// @dev Tracks if a listing has been minted
    mapping(uint256 => bool) private _listingMinted;

    /// @dev Maps archived listings to their latest versions
    mapping(uint256 => uint256) private _listingVersions;

    // EVENTS
    /// @notice Emitted when a listing is updated with a new version
    event ListingVersionCreated(
        uint256 indexed oldListingId,
        uint256 indexed newListingId,
        string note
    );

    // MODIFIERS

    /// @dev Ensures listing exists
    modifier listingExists(uint256 listingId) {
        if (listingId >= _nextListingId) revert InvalidListingId();
        _;
    }

    /// @dev Ensures caller is listing creator
    modifier onlyCreator(uint256 listingId) {
        if (_listings[listingId].creator != msg.sender)
            revert UnauthorizedAccess();
        _;
    }

    /// @dev Ensures listing is in active state
    modifier onlyActive(uint256 listingId) {
        if (_listings[listingId].state != ListingState.Active)
            revert InvalidListingState();
        _;
    }

    // CORE FUNCTIONS

    /// @inheritdoc IListing
    function createListing(
        string memory title,
        string memory details,
        string[] memory proofs,
        string memory category
    ) external returns (uint256) {
        // Input validation
        if (bytes(title).length == 0) revert EmptyTitle();
        if (bytes(details).length == 0) revert EmptyDetails();
        if (proofs.length == 0) revert NoProofs();

        // Check for duplicate listing
        for (uint256 i = 0; i < _nextListingId; i++) {
            Listing memory existingListing = _listings[i];
            if (
                keccak256(abi.encodePacked(existingListing.title)) == keccak256(abi.encodePacked(title)) &&
                keccak256(abi.encodePacked(existingListing.details)) == keccak256(abi.encodePacked(details)) &&
                existingListing.creator == msg.sender &&
                existingListing.state == ListingState.Active
            ) {
                revert ListingAlreadyMinted();
            }
        }

        uint256 newListingId = _nextListingId++;

        _listings[newListingId] = Listing({
            id: newListingId,
            creator: msg.sender,
            title: title,
            details: details,
            proofs: proofs,
            category: category,
            createdAt: block.timestamp,
            state: ListingState.Active,
            linkedToId: 0,
            archiveNote: ""
        });

        _listingCounts[newListingId] = ListingTypes.ListingCount({
            attestCount: 0,
            refuteCount: 0
        });

        emit ListingCreated(newListingId, msg.sender);
        return newListingId;
    }

    /// @inheritdoc IListing
    function archiveListing(
        uint256 listingId,
        uint256 newListingId,
        string memory note
    ) 
        external 
        listingExists(listingId) 
        onlyCreator(listingId)
        onlyActive(listingId)
    {
        // Validate new listing if provided
        if (newListingId != 0) {
            if (newListingId >= _nextListingId) revert InvalidLinkedListing();
            if (_listings[newListingId].state != ListingState.Active)
                revert InvalidLinkedListing();
            
            // Update version mapping
            _listingVersions[listingId] = newListingId;
        }

        Listing storage listing = _listings[listingId];
        listing.state = ListingState.Archived;
        listing.linkedToId = newListingId;
        listing.archiveNote = note;

        emit ListingStateChanged(listingId, ListingState.Archived, note);
        if (newListingId != 0) {
            emit ListingVersionCreated(listingId, newListingId, note);
        }
    }

    /// @notice Sets a listing as minted
    /// @dev Called by the main contract when an NFT is minted from a listing
    /// @param listingId The ID of the listing being minted
    function _setListingMinted(uint256 listingId) internal listingExists(listingId) {
        if (_listingMinted[listingId]) revert ListingAlreadyMinted();
        _listings[listingId].state = ListingState.Minted;
        _listingMinted[listingId] = true;
        emit ListingStateChanged(listingId, ListingState.Minted, "");
    }

    /// @notice Checks if a listing can be minted based on attestation count
    /// @param listingId The ID of the listing to check
    /// @return bool indicating if listing can be minted
    function canBeMinted(uint256 listingId) internal view virtual returns (bool) {
        if (_listingMinted[listingId]) return false;
        if (_listings[listingId].state != ListingState.Active) return false;
        return _listingCounts[listingId].attestCount >= MIN_ATTESTATIONS_FOR_MINT;
    }

    /// @notice Gets the latest version of a listing
    /// @param listingId The ID of the listing to check
    /// @return The ID of the latest version of the listing
    function getLatestVersion(uint256 listingId) external view returns (uint256) {
        uint256 currentId = listingId;
        while (_listingVersions[currentId] != 0) {
            currentId = _listingVersions[currentId];
        }
        return currentId;
    }

    /// @inheritdoc IListing
    function getListing(
        uint256 listingId
    ) public view returns (IListing.Listing memory) {
        return _listings[listingId];
    }

    /// @inheritdoc IListing
    function isListingActive(
        uint256 listingId
    ) external view listingExists(listingId) returns (bool) {
        return _listings[listingId].state == ListingState.Active;
    }

    /// @inheritdoc IListing
    function canEditListing(
        uint256 listingId
    ) external view listingExists(listingId) returns (bool) {
        Listing storage listing = _listings[listingId];
        return
            listing.state == ListingState.Active &&
            _listingCounts[listingId].attestCount == 0 &&
            _listingCounts[listingId].refuteCount == 0;
    }

    /// @inheritdoc IListing
    function getTotalListings() external view returns (uint256) {
        return _nextListingId;
    }
}
