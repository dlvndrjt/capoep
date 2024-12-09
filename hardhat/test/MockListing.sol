// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../contracts/interfaces/IListing.sol";

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
}
