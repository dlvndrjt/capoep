// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CAPOL is ERC721 {
    using Counters for Counters.Counter;

    Counters.Counter private _listingIdCounter;
    Counters.Counter private _tokenIdCounter;

    struct Listing {
        string title;
        string details;
        string[] proofs;
        address creator;
        bool minted;
    }

    struct Vote {
        address voter;
        bool thumbsUp;
        string comment;
    }

    struct Comment {
        address commenter;
        string content;
        int256 votes; // Upvotes (+1) and downvotes (-1)
    }

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => Vote[]) public votes;
    mapping(uint256 => Comment[]) public comments;

    event ListingCreated(uint256 indexed listingId, address indexed creator);
    event ListingMinted(uint256 indexed listingId, address indexed owner, uint256 indexed tokenId);
    event VoteAdded(uint256 indexed listingId, address indexed voter);
    event CommentAdded(uint256 indexed listingId, address indexed commenter);

    constructor() ERC721("Community Attested Proof of Learning", "CAPOL") {}

    function createListing(
        string memory title,
        string memory details,
        string[] memory proofs
    ) external {
        uint256 listingId = _listingIdCounter.current();
        _listingIdCounter.increment();

        listings[listingId] = Listing({
            title: title,
            details: details,
            proofs: proofs,
            creator: msg.sender,
            minted: false
        });

        emit ListingCreated(listingId, msg.sender);
    }

    function addVote(
        uint256 listingId,
        bool thumbsUp,
        string memory comment
    ) external {
        require(listings[listingId].creator != address(0), "Listing does not exist");

        votes[listingId].push(Vote({
            voter: msg.sender,
            thumbsUp: thumbsUp,
            comment: comment
        }));

        emit VoteAdded(listingId, msg.sender);
    }

    function addComment(
        uint256 listingId,
        string memory content
    ) external {
        require(listings[listingId].creator != address(0), "Listing does not exist");

        comments[listingId].push(Comment({
            commenter: msg.sender,
            content: content,
            votes: 0
        }));

        emit CommentAdded(listingId, msg.sender);
    }

    function mintListing(uint256 listingId) external {
        Listing storage listing = listings[listingId];
        require(listing.creator == msg.sender, "Only the creator can mint this listing");
        require(!listing.minted, "Listing already minted");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _mint(msg.sender, tokenId);

        listing.minted = true;

        emit ListingMinted(listingId, msg.sender, tokenId);
    }

    function voteOnComment(
        uint256 listingId,
        uint256 commentIndex,
        bool thumbsUp
    ) external {
        require(listings[listingId].creator != address(0), "Listing does not exist");
        require(commentIndex < comments[listingId].length, "Invalid comment index");

        Comment storage comment = comments[listingId][commentIndex];
        comment.votes += thumbsUp ? int256(1) : int256(-1);
    }
}
