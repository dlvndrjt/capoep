// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../interfaces/IListing.sol";
import "../libraries/ListingTypes.sol";

/// @title ListingModule
/// @notice Implements educational achievement listing management for CAPOEP
/// @dev Handles listing lifecycle, versioning, and state management
contract ListingModule is IListing {
    // CUSTOM ERRORS
    error InvalidListingId();
    error UnauthorizedAccess();
    error InvalidListingState();
    error EmptyTitle();
    error EmptyDetails();
    error NoProofs();

    // STATE VARIABLES

    /// @dev Counter for generating unique listing IDs
    uint256 private _nextListingId;

    /// @dev Primary storage for all listings
    mapping(uint256 => Listing) private _listings;

    /// @dev Storage for listing vote counts
    mapping(uint256 => ListingTypes.ListingCount) private _listingCounts;

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
    ) external listingExists(listingId) onlyCreator(listingId) {
        Listing storage listing = _listings[listingId];

        if (listing.state != ListingState.Active) revert InvalidListingState();

        listing.state = ListingState.Archived;
        listing.linkedToId = newListingId;
        listing.archiveNote = note;

        emit ListingStateChanged(listingId, ListingState.Archived, note);
    }

    // VIEW FUNCTIONS

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

    // INTERNAL FUNCTIONS

    /// @notice Updates a listing's state to Minted
    /// @dev Internal function called when an NFT is minted from a listing
    /// @param listingId The ID of the listing being minted
    function _setListingMinted(uint256 listingId) internal {
        _listings[listingId].state = ListingState.Minted;
        emit ListingStateChanged(listingId, ListingState.Minted, "");
    }

    /// @notice Checks if a listing has enough attestations to be minted
    /// @dev Internal function to verify minting requirements
    /// @param listingId The ID of the listing to check
    /// @return bool indicating if listing can be minted
    function canBeMinted(uint256 listingId) internal view virtual returns (bool) {
        return _listingCounts[listingId].attestCount >= 2;
    }

    struct ListingCount {
        uint256 attestCount;
        uint256 refuteCount;
    }
}
