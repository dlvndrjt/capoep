// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../interfaces/IMetadata.sol";
import "../Base64.sol";
import "../interfaces/IListing.sol";

/// @title MetadataModule
/// @notice Implements dynamic NFT metadata generation for CAPOEP
/// @dev Handles SVG generation and metadata formatting
contract MetadataModule is IMetadata {
    // CUSTOM ERRORS

    error TokenDoesNotExist();
    error InvalidTokenId();
    error InvalidAddress();

    // CORE FUNCTIONS
    /// @inheritdoc IMetadata
    function generateTokenURI(
        uint256 tokenId
    ) external view override returns (string memory) {
        MetadataAttribute[] memory attributes = getAttributes(tokenId);
        string memory svg = generateSVG(tokenId);

        string memory json = string(
            abi.encodePacked(
                '{"name":"CAPOEP #',
                _toString(tokenId),
                '","description":"Community Attested Proof of Education Protocol"',
                ',"image":"data:image/svg+xml;base64,',
                Base64.encode(bytes(svg)),
                '","attributes":',
                _attributesToJson(attributes),
                "}"
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(json))
                )
            );
    }

    /// @inheritdoc IMetadata
    function generateSVG(
        uint256 tokenId
    ) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" width="500" height="500">',
                    "<style>text{font-family:sans-serif;}</style>",
                    '<rect width="100%" height="100%" fill="#1a1b1e"/>',
                    '<text x="50%" y="20%" text-anchor="middle" fill="white" font-size="24">',
                    "CAPOEP #",
                    _toString(tokenId),
                    "</text>",
                    _generateSVGAttributes(),
                    "</svg>"
                )
            );
    }

    /// @notice Get attributes for a token
    /// @param tokenId The ID of the token
    /// @return Array of metadata attributes
    function getAttributes(
        uint256 tokenId
    ) public view returns (MetadataAttribute[] memory) {
        IListing.Listing memory listing = _listingModule.getListing(tokenId);

        MetadataAttribute[] memory attributes = new MetadataAttribute[](5);
        attributes[0] = MetadataAttribute("Category", listing.category);
        attributes[1] = MetadataAttribute("Title", listing.title);
        attributes[2] = MetadataAttribute(
            "Creator",
            addressToString(listing.creator)
        );

        (uint256 attestCount,) = _listingModule.getListingCounts(tokenId);
        attributes[3] = MetadataAttribute(
            "Attestations",
            _toString(attestCount)
        );
        attributes[4] = MetadataAttribute("Status", "Verified");

        return attributes;
    }

    // HELPER FUNCTIONS

    /// @dev Converts attributes array to JSON string
    function _attributesToJson(
        MetadataAttribute[] memory attributes
    ) internal pure returns (string memory) {
        string memory attrs = "[";

        for (uint i = 0; i < attributes.length; i++) {
            if (i > 0) attrs = string(abi.encodePacked(attrs, ","));
            attrs = string(
                abi.encodePacked(
                    attrs,
                    '{"trait_type":"',
                    attributes[i].traitType,
                    '","value":"',
                    attributes[i].value,
                    '"}'
                )
            );
        }

        return string(abi.encodePacked(attrs, "]"));
    }

    /// @dev Generates SVG elements for attributes
    function _generateSVGAttributes() internal view returns (string memory) {
        MetadataAttribute[] memory attributes = getAttributes(0);
        string memory elements = "";
        uint256 yPos = 30;

        for (uint i = 0; i < attributes.length; i++) {
            elements = string(
                abi.encodePacked(
                    elements,
                    '<text x="50%" y="',
                    _toString(yPos),
                    '%" text-anchor="middle" fill="#888" font-size="16">',
                    attributes[i].traitType,
                    ": ",
                    attributes[i].value,
                    "</text>"
                )
            );
            yPos += 10;
        }

        return elements;
    }

    /// @dev Converts uint256 to string
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";

        uint256 temp = value;
        uint256 digits;

        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }

    // STATE VARIABLES
    IListing private immutable _listingModule;

    // CONSTRUCTOR
    constructor(address listingModule) {
        if (listingModule == address(0)) revert InvalidAddress();
        _listingModule = IListing(listingModule);
    }

    // HELPER FUNCTIONS
    function addressToString(
        address addr
    ) internal pure returns (string memory) {
        bytes memory buffer = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(
                uint8(uint256(uint160(addr)) / (2 ** (8 * (19 - i))))
            );
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            buffer[2 * i] = char(hi);
            buffer[2 * i + 1] = char(lo);
        }
        return string(buffer);
    }

    function char(bytes1 b) internal pure returns (bytes1) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}
