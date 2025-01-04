// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../libraries/LibAppStorage.sol";

contract NFTFacet is ERC721, ERC721URIStorage {
    AppStorage internal s;

    // Events
    event Minted(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 indexed entryId,
        string tokenURI
    );
    event Burned(uint256 indexed tokenId, address indexed owner);

    constructor() ERC721("CAPOEP", "CAPOEP") {}

    // Function to mint a CAPOEP NFT
    function mintCAPOEP(uint256 entryId, string memory tokenURI) external {
        // Check if the entry exists
        require(s.entries[entryId].id != 0, "Entry does not exist");

        // Check if the caller is the creator of the entry
        require(
            s.entries[entryId].creator == msg.sender,
            "Only the entry creator can mint"
        );

        // Check if the entry has at least 2 attest votes
        require(
            s.entries[entryId].totalAttestCount >= 2,
            "Entry does not have enough attest votes"
        );

        // Check if the entry has not already been minted
        require(
            s.entries[entryId].state != EntryState.Minted,
            "Entry already minted"
        );

        // Generate a new token ID
        uint256 tokenId = s.nextTokenId;
        s.nextTokenId++;

        // Update storage
        s.tokenIdToEntryId[tokenId] = entryId;
        s.tokenIdToTokenURI[tokenId] = tokenURI;

        // Update the entry state to Minted
        s.entries[entryId].state = EntryState.Minted;

        // Mint the NFT using OpenZeppelin's ERC721
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);

        // Emit the Minted event
        emit Minted(tokenId, msg.sender, entryId, tokenURI);
    }

    // Function to burn a CAPOEP NFT
    function burnCAPOEP(uint256 tokenId) external {
        // Check if the caller is the owner of the token
        require(ownerOf(tokenId) == msg.sender, "Not the token owner");

        // Get the entry ID associated with the token
        uint256 entryId = s.tokenIdToEntryId[tokenId];

        // Update storage
        delete s.tokenIdToEntryId[tokenId];
        delete s.tokenIdToTokenURI[tokenId];

        // Update the entry state to Archived
        s.entries[entryId].state = EntryState.Archived;

        // Burn the NFT using OpenZeppelin's ERC721
        _burn(tokenId);

        // Emit the Burned event
        emit Burned(tokenId, msg.sender);
    }

    // Override tokenURI to use AppStorage
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return s.tokenIdToTokenURI[tokenId];
    }

    // Override _burn to use AppStorage
    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}
