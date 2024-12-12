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
    error UnauthorizedCaller();
    error EmptyCategory();

    // CONSTANTS
    /// @dev Minimum number of attestations required for minting
    uint256 public constant MIN_ATTESTATIONS_FOR_MINT = 2;

    // STATE VARIABLES
    /// @dev Address of the voting module
    address private immutable _votingModule;

    /// @dev Address of the CAPOEP contract
    address private immutable _capoepAddress;

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

    /// @dev Maps listing hashes to prevent duplicates
    mapping(bytes32 => bool) private _listingHashes;

    /// @dev Maps version chains
    mapping(uint256 => uint256[]) private _versionHistory;

    constructor(address capoepAddress, address votingModule) {
        _capoepAddress = capoepAddress;
        _votingModule = votingModule;
    }

    // MODIFIERS
    modifier onlyVotingModule() {
        if (msg.sender != _votingModule) revert UnauthorizedCaller();
        _;
    }

    modifier onlyCapoep() {
        if (msg.sender != _capoepAddress) revert UnauthorizedCaller();
        _;
    }

    /// @dev Ensures listing exists
    modifier listingExists(uint256 listingId) {
        if (listingId >= _nextListingId) revert InvalidListingId();
        _;
    }

    /// @dev Ensures caller is listing creator
    modifier onlyCreator(uint256 listingId) {
        if (msg.sender != _listings[listingId].creator)
            revert UnauthorizedCaller();
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
        if (bytes(category).length == 0) revert EmptyCategory();

        // Create listing hash for duplicate check
        bytes32 listingHash = keccak256(
            abi.encodePacked(title, details, msg.sender)
        );

        // Check for duplicates more efficiently
        if (_listingHashes[listingHash]) revert ListingAlreadyExists();
        _listingHashes[listingHash] = true;

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
    ) external override {
        require(msg.sender == _listings[listingId].creator, "Not creator");
        require(_listings[listingId].state == ListingState.Active, "Not active");
        
        _listings[listingId].state = ListingState.Archived;
        if (newListingId != 0) {
            _listings[listingId].linkedToId = newListingId;
        }
        _listings[listingId].archiveNote = note;
        
        emit ListingStateChanged(listingId, ListingState.Archived, note);
    }

    /// @notice Sets a listing as minted
    /// @dev Called by the main contract when an NFT is minted from a listing
    /// @param listingId The ID of the listing being minted
    function _setListingMinted(uint256 listingId) external onlyCapoep {
        if (_listingMinted[listingId]) revert ListingAlreadyMinted();
        _listings[listingId].state = ListingState.Minted;
        _listingMinted[listingId] = true;
        emit ListingStateChanged(listingId, ListingState.Minted, "");
    }

    /// @notice Checks if a listing can be minted based on attestation count
    /// @param listingId The ID of the listing to check
    /// @return bool indicating if listing can be minted
    function canBeMinted(uint256 listingId) public view returns (bool) {
        if (_listingMinted[listingId]) return false;
        if (_listings[listingId].state != ListingState.Active) return false;
        return
            _listingCounts[listingId].attestCount >= MIN_ATTESTATIONS_FOR_MINT;
    }

    /// @notice Gets the latest version of a listing
    /// @param listingId The ID of the listing to check
    /// @return The ID of the latest version of the listing
    function getLatestVersion(
        uint256 listingId
    ) external view returns (uint256) {
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
    function canEditListing(uint256 listingId) public view returns (bool) {
        // Can only edit if:
        // 1. Listing exists
        // 2. Is active
        // 3. Has no votes
        if (listingId >= _nextListingId) return false;
        if (_listings[listingId].state != ListingState.Active) return false;
        return !hasVotes(listingId);
    }

    /// @inheritdoc IListing
    function getTotalListings() public view returns (uint256) {
        return _nextListingId;
    }

    /// @notice Updates listing counts
    /// @dev Called by the main contract to update listing counts
    /// @param listingId The ID of the listing to update
    /// @param isAttestation Whether the update is an attestation
    function updateListingCounts(
        uint256 listingId,
        bool isAttestation
    ) external onlyVotingModule {
        require(
            _listings[listingId].state == ListingState.Active,
            "Listing not active"
        );

        if (isAttestation) {
            _listingCounts[listingId].attestCount++;
        } else {
            _listingCounts[listingId].refuteCount++;
        }

        emit ListingCountsUpdated(listingId, isAttestation);
    }

    /// @notice Adds a new version of a listing
    /// @dev Called by the main contract to add a new version of a listing
    /// @param oldListingId The ID of the listing being archived
    /// @param archivalNote The note for the archival
    /// @param title The title of the new listing
    /// @param details The details of the new listing
    /// @param proofs The proofs of the new listing
    /// @param category The category of the new listing
    /// @return The ID of the new listing
    function archiveAndCreateNewVersion(
        uint256 oldListingId,
        string memory archivalNote,
        string memory title,
        string memory details,
        string[] memory proofs,
        string memory category
    ) external onlyCreator(oldListingId) returns (uint256) {
        require(
            _listings[oldListingId].state == ListingState.Active,
            "Listing not active"
        );

        // Create new version using this.createListing to call it externally
        uint256 newListingId = this.createListing(title, details, proofs, category);

        // Archive old listing
        _listings[oldListingId].state = ListingState.Archived;
        _listings[oldListingId].linkedToId = newListingId;
        _listings[oldListingId].archiveNote = archivalNote;

        // Record version history
        _versionHistory[oldListingId].push(newListingId);

        emit ListingStateChanged(
            oldListingId,
            ListingState.Archived,
            archivalNote
        );
        emit ListingVersionCreated(oldListingId, newListingId, archivalNote);

        return newListingId;
    }

    /// @notice Gets version history
    /// @dev Called by the main contract to get version history
    /// @param listingId The ID of the listing to get version history
    /// @return The version history of the listing
    function getVersionHistory(
        uint256 listingId
    ) external view returns (uint256[] memory) {
        return _versionHistory[listingId];
    }

    /// @notice Gets vote counts for a listing
    /// @dev Called by the main contract to get vote counts for a listing
    /// @param listingId The ID of the listing to get vote counts
    /// @return attestCount The number of attestations for the listing
    /// @return refuteCount The number of refutes for the listing
    function getListingCounts(
        uint256 listingId
    ) external view returns (uint256 attestCount, uint256 refuteCount) {
        ListingTypes.ListingCount memory counts = _listingCounts[listingId];
        return (counts.attestCount, counts.refuteCount);
    }

    /// @notice Gets the complete version chain for a listing
    /// @param listingId The ID of the listing to check
    /// @return Array of listing IDs in version order
    function getVersionChain(
        uint256 listingId
    ) external view returns (uint256[] memory) {
        uint256[] memory chain = new uint256[](getTotalListings());
        uint256 chainLength = 0;

        // Add original listing
        chain[chainLength++] = listingId;

        // Follow version chain
        uint256 currentId = listingId;
        while (_listingVersions[currentId] != 0) {
            currentId = _listingVersions[currentId];
            chain[chainLength++] = currentId;
        }

        // Create correctly sized array
        uint256[] memory result = new uint256[](chainLength);
        for (uint256 i = 0; i < chainLength; i++) {
            result[i] = chain[i];
        }

        return result;
    }

    /// @notice Edit a listing before it receives any votes
    /// @param listingId The ID of the listing to edit
    /// @param title New title
    /// @param details New details
    /// @param proofs New proofs
    /// @param category New category
    function editListing(
        uint256 listingId,
        string memory title,
        string memory details,
        string[] memory proofs,
        string memory category
    ) external onlyCreator(listingId) {
        // Check if listing can be edited
        require(canEditListing(listingId), "Listing cannot be edited");

        // Input validation
        if (bytes(title).length == 0) revert EmptyTitle();
        if (bytes(details).length == 0) revert EmptyDetails();
        if (proofs.length == 0) revert NoProofs();

        // Update listing
        Listing storage listing = _listings[listingId];
        listing.title = title;
        listing.details = details;
        listing.proofs = proofs;
        listing.category = category;

        emit ListingStateChanged(
            listingId,
            ListingState.Active,
            "Listing edited"
        );
    }

    /// @notice Check if a listing has any votes
    /// @param listingId The ID of the listing to check
    /// @return bool indicating if listing has votes
    function hasVotes(uint256 listingId) public view returns (bool) {
        ListingTypes.ListingCount memory counts = _listingCounts[listingId];
        return counts.attestCount > 0 || counts.refuteCount > 0;
    }

    // EVENTS
    event ListingVersionCreated(
        uint256 indexed oldListingId,
        uint256 indexed newListingId,
        string note
    );
    event ListingCountsUpdated(uint256 indexed listingId, bool isAttestation);
    event ListingDuplicate(
        address indexed creator,
        bytes32 indexed contentHash,
        string message
    );
}
