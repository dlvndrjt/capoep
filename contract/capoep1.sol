// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing the ERC721 implementation from OpenZeppelin
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Define the CAPOEP contract, inheriting from ERC721
contract CAPOEP is ERC721 {
    using Counters for Counters.Counter;
    
    // Structure to hold listing details
    struct Listing {
        string title;
        string description;
        string proof;
        uint256 upvotes;
        uint256 downvotes;
        bool isMinted;
    }

    // Mapping of listing ID to Listing structure
    mapping(uint256 => Listing) public listings;
    
    // Counter for generating unique listing IDs and token IDs
    Counters.Counter private _listingIdCounter;
    Counters.Counter private _tokenIdCounter;
    
    // The required threshold of upvotes to mint an NFT
    uint256 public voteThreshold;

    // Event for listing creation
    event ListingCreated(uint256 listingId, address creator);
    // Event for minting an NFT
    event NFTMinted(uint256 listingId, uint256 tokenId, address creator);

    // Constructor to set the token name and symbol
    constructor(string memory name, string memory symbol, uint256 _voteThreshold) 
        ERC721(name, symbol) 
    {
        voteThreshold = _voteThreshold;
    }

    // Function to create a new listing
    function createListing(string memory title, string memory description, string memory proof) external {
        _listingIdCounter.increment();
        uint256 listingId = _listingIdCounter.current();
        
        listings[listingId] = Listing({
            title: title,
            description: description,
            proof: proof,
            upvotes: 0,
            downvotes: 0,
            isMinted: false
        });

        emit ListingCreated(listingId, msg.sender);
    }

    // Function to upvote a listing
    function upvoteListing(uint256 listingId) external {
        require(!listings[listingId].isMinted, "Listing already minted");

        listings[listingId].upvotes += 1;

        // Check if the upvotes meet the threshold to mint the NFT
        if (listings[listingId].upvotes >= voteThreshold && !listings[listingId].isMinted) {
            _mintNFT(listingId);
        }
    }

    // Function to downvote a listing
    function downvoteListing(uint256 listingId) external {
        require(!listings[listingId].isMinted, "Listing already minted");
        listings[listingId].downvotes += 1;
    }

    // Internal function to mint the NFT once the threshold is met
    function _mintNFT(uint256 listingId) internal {
        require(listings[listingId].upvotes >= voteThreshold, "Not enough upvotes to mint");

        // Generate the next token ID
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        
        // Mint the NFT to the creator of the listing
        _safeMint(msg.sender, tokenId);
        
        // Mark the listing as minted
        listings[listingId].isMinted = true;
        
        emit NFTMinted(listingId, tokenId, msg.sender);
    }

    // Function to get the details of a listing
    function getListing(uint256 listingId) external view returns (Listing memory) {
        return listings[listingId];
    }

    // Function to update the vote threshold (can be restricted to admin)
    function setVoteThreshold(uint256 newThreshold) external {
        voteThreshold = newThreshold;
    }
}
