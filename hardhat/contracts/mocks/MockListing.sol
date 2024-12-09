// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../interfaces/IListing.sol";

contract MockListing is IListing {
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
