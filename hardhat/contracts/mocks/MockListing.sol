// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../interfaces/IListing.sol";

abstract contract MockListing is IListing {
    mapping(uint256 => uint256) private _attestCounts;
    mapping(uint256 => uint256) private _refuteCounts;
    mapping(uint256 => uint256[]) private _versionHistory;
    mapping(uint256 => bool) private _hasVotesCasted;

    function _setListingMinted(uint256 listingId) external override {
        // Mock implementation
    }

    function canBeMinted(
        uint256 /* listingId */
    ) external pure override returns (bool) {
        return true; // Mock implementation
    }

    function getListingCounts(uint256 listingId) 
        external 
        view 
        override 
        returns (uint256 attestCount, uint256 refuteCount) 
    {
        return (_attestCounts[listingId], _refuteCounts[listingId]);
    }

    function getVersionHistory(uint256 listingId) 
        external 
        view 
        override 
        returns (uint256[] memory) 
    {
        return _versionHistory[listingId];
    }

    function hasVotes(uint256 listingId) external view override returns (bool) {
        return _hasVotesCasted[listingId];
    }

    function updateListingCounts(uint256 listingId, bool isAttestation) external override {
        if (isAttestation) {
            _attestCounts[listingId]++;
        } else {
            _refuteCounts[listingId]++;
        }
        _hasVotesCasted[listingId] = true;
    }

    function isListingActive(uint256 /* _listingId */) external pure returns (bool) {
        return true;
    }

    function createListing(
        string memory /* _title */,
        string memory /* _details */,
        string[] memory /* _imageUrls */,
        string memory /* _category */
    ) external pure returns (uint256) {
        return 0;
    }

    function updateListing(
        uint256 /* _listingId */,
        string memory /* _title */,
        string memory /* _details */,
        string[] memory /* _imageUrls */
    ) external pure {}

    function closeListing(uint256 /* _listingId */) external pure {}

    function archiveListing(
        uint256 /* _listingId */,
        uint256 /* _newListingId */,
        string memory /* _note */
    ) external pure {}

    function canEditListing(uint256 /* _listingId */) external pure returns (bool) {
        return true;
    }

    function getListing(
        uint256 /* _listingId */
    ) external pure returns (Listing memory) {
        return Listing({
            id: 0,
            creator: address(0),
            title: "",
            details: "",
            proofs: new string[](0),
            category: "",
            createdAt: 0,
            state: ListingState.Active,
            linkedToId: 0,
            archiveNote: ""
        });
    }

    function getTotalListings() external pure returns (uint256) {
        return 0;
    }
}
