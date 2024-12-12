// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @title IMetadata Interface
/// @notice Interface for NFT metadata generation in CAPOEP
/// @dev Implements dynamic metadata and SVG generation
interface IMetadata {
    // STRUCTS

    /// @notice Structure for NFT metadata attributes
    struct MetadataAttribute {
        string traitType;
        string value;
    }

    // CORE FUNCTIONS

    /// @notice Generates complete metadata for a token
    /// @param tokenId The ID of the token
    /// @return Complete metadata URI as base64 encoded JSON
    function generateTokenURI(
        uint256 tokenId
    ) external view returns (string memory);

    /// @notice Generates SVG image for a token
    /// @param tokenId The ID of the token
    /// @return SVG image data
    function generateSVG(uint256 tokenId) external view returns (string memory);

    /// @notice Gets metadata attributes
    /// @param tokenId The ID of the token
    /// @return Array of metadata attributes
    function getAttributes(uint256 tokenId) external view returns (MetadataAttribute[] memory);
}
