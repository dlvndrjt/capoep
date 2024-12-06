// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721Pausable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./Base64.sol";

/// @title CAPOEP - Community Attested Proof of Education Protocol
/// @author Delta Sigma
/// @notice This contract manages educational achievements with community attestation
/// @dev Implements ERC721 with additional functionality for community verification
/// @custom:security-contact test@email.com
contract CAPOEP is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Pausable,
    Ownable,
    ERC721Burnable
{
    // ENUMS

    // Simple explanation: These are the different states a listing can be in
    /// @notice Enum representing the possible states of a listing
    /// @dev Used to track listing lifecycle
    enum ListingState {
        Active, // Listing is active and can receive votes
        Archived, // Listing has been archived
        Minted // Listing has been minted as NFT
    }

    // STATE VARIABLES

    // Simple explanation: This keeps track of what number we're at for creating new tokens
    /// @dev Counter for generating unique token IDs
    uint256 private _nextTokenId;

    // Simple explanation: This keeps track of what number we're at for creating new listings
    /// @dev Counter for generating unique listing IDs
    uint256 private _nextListingId;

    /// @dev Counter for generating unique comment IDs
    uint256 private _nextCommentId;

    // MAPPINGS

    // Simple explanation: This maps IDs to actual listings, like a database
    /// @notice Mapping from listing ID to Listing struct
    /// @dev Primary storage for all listings
    mapping(uint256 => Listing) public listings;

    /// @notice Maps listing IDs to voter addresses to their votes
    /// @dev Primary storage for vote information
    mapping(uint256 => mapping(address => Vote)) public votes;

    /// @notice Maps listing IDs to arrays of voter addresses
    /// @dev Used to track all voters for a listing
    mapping(uint256 => address[]) public listingVoters;

    /// @notice Maps listing IDs to arrays of comments
    mapping(uint256 => Comment[]) public listingComments;

    /// @notice Maps comment IDs to voter addresses to their vote status
    mapping(uint256 => mapping(address => bool)) public commentVotes;

    /// @notice Maps addresses to their reputation scores
    /// @dev Tracks all reputation points earned through attestations and votes
    mapping(address => int256) public reputationScores;

    // STRUCTS

    // Simple explanation: This is what a listing looks like - all its properties in one place
    /// @notice Structure containing all information about an educational listing
    /// @dev Main data structure for storing listing information
    struct Listing {
        uint256 id; // Unique identifier
        address creator; // Address of listing creator
        string title; // Title of the achievement/content
        string details; // Detailed description
        string[] proofs; // Array of proof URIs/links
        string category; // Educational category
        uint256 attestCount; // Number of attestations
        uint256 refuteCount; // Number of refutations
        uint256 createdAt; // Timestamp of creation
        ListingState state; // Current state of listing
        uint256 linkedToId; // ID of linked listing (for versioning)
        string archiveNote; // Note explaining why archived (if applicable)
    }

    /// @notice Structure for storing vote information
    /// @dev Tracks individual votes and their associated comments
    struct Vote {
        bool isAttest; // true for attest, false for refute
        string comment; // Required comment explaining the vote
        uint256 timestamp; // When the vote was cast
        uint256 upvotes; // Number of upvotes on this vote
        uint256 downvotes; // Number of downvotes on this vote
    }

    /// @notice Structure for storing comment information
    /// @dev Supports nested comments and voting
    struct Comment {
        uint256 id; // Unique identifier for the comment
        address author; // Address of comment author
        string content; // Comment content
        uint256 timestamp; // When comment was created
        uint256 parentId; // ID of parent comment (0 for top-level)
        uint256 upvotes; // Number of upvotes
        uint256 downvotes; // Number of downvotes
        bool isVoteComment; // Whether this is attached to a vote
    }

    // CONSTRUCTOR

    constructor(
        address initialOwner
    ) ERC721("CAPOEP", "CAPOEP") Ownable(initialOwner) {}

    // CORE FUNCTIONS

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    /// @notice Creates a new educational listing
    /// @dev Emits ListingCreated event upon successful creation
    /// @param title The title of the listing
    /// @param details Detailed description of the achievement/content
    /// @param proofs Array of URIs/links proving the achievement
    /// @param category Educational category of the listing
    /// @return id The unique identifier of the created listing
    function createListing(
        string memory title,
        string memory details,
        string[] memory proofs,
        string memory category
    ) public returns (uint256) {
        // Simple explanation: Get a new unique ID for this listing
        uint256 newListingId = _nextListingId++;

        // Simple explanation: Create a new listing with all the information
        listings[newListingId] = Listing({
            id: newListingId,
            creator: msg.sender,
            title: title,
            details: details,
            proofs: proofs,
            category: category,
            attestCount: 0,
            refuteCount: 0,
            createdAt: block.timestamp,
            state: ListingState.Active,
            linkedToId: 0,
            archiveNote: ""
        });

        // Simple explanation: Tell everyone a new listing was created
        emit ListingCreated(newListingId, msg.sender);

        return newListingId;
    }

    /// @notice Archives a listing and creates a link to a new version
    /// @dev Can only be called by the listing creator when listing is Active
    /// @param listingId The ID of the listing to archive
    /// @param newListingId The ID of the new version (if any)
    /// @param note The reason for archiving
    function archiveListing(
        uint256 listingId,
        uint256 newListingId,
        string memory note
    ) public {
        Listing storage listing = listings[listingId];

        // Simple explanation: Make sure only the creator can archive their listing
        require(msg.sender == listing.creator, "Only creator can archive");

        // Simple explanation: Can only archive active listings
        require(listing.state == ListingState.Active, "Listing must be active");

        // Simple explanation: Update the listing state and link it to the new version
        listing.state = ListingState.Archived;
        listing.linkedToId = newListingId;
        listing.archiveNote = note;

        emit ListingStateChanged(listingId, ListingState.Archived, note);
    }

    /// @notice Updates a listing's state to Minted
    /// @dev Internal function called when an NFT is minted
    /// @param listingId The ID of the listing being minted
    function _setListingMinted(uint256 listingId) internal {
        Listing storage listing = listings[listingId];
        listing.state = ListingState.Minted;
        emit ListingStateChanged(listingId, ListingState.Minted, "");
    }

    /// @notice Cast a vote (attest or refute) on a listing
    /// @param listingId The ID of the listing to vote on
    /// @param isAttest True for attestation, false for refutation
    /// @param comment Required explanation for the vote
    function castVote(
        uint256 listingId,
        bool isAttest,
        string memory comment
    ) public {
        Listing storage listing = listings[listingId];

        // Simple explanation: Make sure listing exists and is active
        require(listing.state == ListingState.Active, "Listing must be active");

        // Simple explanation: Make sure voter hasn't voted before
        require(votes[listingId][msg.sender].timestamp == 0, "Already voted");

        // Simple explanation: Make sure comment isn't empty
        require(bytes(comment).length > 0, "Comment required");

        // Simple explanation: Record the vote
        votes[listingId][msg.sender] = Vote({
            isAttest: isAttest,
            comment: comment,
            timestamp: block.timestamp,
            upvotes: 0,
            downvotes: 0
        });

        // Simple explanation: Add voter to the list and update vote counts
        listingVoters[listingId].push(msg.sender);
        if (isAttest) {
            listing.attestCount++;
        } else {
            listing.refuteCount++;
        }

        // Update reputation for listing creator
        _updateReputation(
            listing.creator,
            isAttest ? int256(1) : int256(-1),
            isAttest ? "Received attestation" : "Received refutation"
        );

        emit VoteCast(listingId, msg.sender, isAttest, comment);
    }

    /// @notice Give feedback on a vote (upvote/downvote)
    /// @param listingId The listing ID
    /// @param voter The address of the voter
    /// @param isUpvote True for upvote, false for downvote
    function giveVoteFeedback(
        uint256 listingId,
        address voter,
        bool isUpvote
    ) public {
        Vote storage vote = votes[listingId][voter];

        // Simple explanation: Make sure the vote exists
        require(vote.timestamp != 0, "Vote doesn't exist");

        // Simple explanation: Update the vote's feedback counts
        if (isUpvote) {
            vote.upvotes++;
        } else {
            vote.downvotes++;
        }

        emit VoteFeedback(listingId, voter, msg.sender, isUpvote);
    }

    /// @notice Add a comment to a listing
    /// @param listingId The ID of the listing to comment on
    /// @param content The comment content
    /// @param parentId ID of parent comment (0 for top-level)
    /// @return commentId The ID of the created comment
    function addComment(
        uint256 listingId,
        string memory content,
        uint256 parentId
    ) public returns (uint256) {
        // Simple explanation: Make sure listing exists and is active or archived
        require(
            listings[listingId].state != ListingState.Minted,
            "Cannot comment on minted listings"
        );

        // Simple explanation: Make sure comment isn't empty
        require(bytes(content).length > 0, "Comment cannot be empty");

        uint256 commentId = _nextCommentId++;

        Comment memory newComment = Comment({
            id: commentId,
            author: msg.sender,
            content: content,
            timestamp: block.timestamp,
            parentId: parentId,
            upvotes: 0,
            downvotes: 0,
            isVoteComment: false
        });

        listingComments[listingId].push(newComment);

        emit CommentCreated(listingId, commentId, msg.sender, parentId);

        return commentId;
    }

    /// @notice Vote on a comment and update reputation
    /// @param listingId The listing ID
    /// @param commentId The comment ID
    /// @param isUpvote True for upvote, false for downvote
    function voteOnComment(
        uint256 listingId,
        uint256 commentId,
        bool isUpvote
    ) public {
        Comment[] storage comments = listingComments[listingId];

        for (uint i = 0; i < comments.length; i++) {
            if (comments[i].id == commentId) {
                require(
                    !commentVotes[commentId][msg.sender],
                    "Already voted on this comment"
                );

                if (isUpvote) {
                    comments[i].upvotes++;
                    _updateReputation(
                        comments[i].author,
                        int256(1),
                        "Comment upvoted"
                    );
                } else {
                    comments[i].downvotes++;
                    _updateReputation(
                        comments[i].author,
                        int256(-1),
                        "Comment downvoted"
                    );
                }

                commentVotes[commentId][msg.sender] = true;
                emit CommentVoted(commentId, msg.sender, isUpvote);
                break;
            }
        }
    }

    /// @notice Mint a CAPOEP NFT from a verified listing
    /// @dev Requires listing to have minimum attestations
    /// @param listingId The ID of the listing to mint
    function mintFromListing(uint256 listingId) public {
        Listing storage listing = listings[listingId];

        // Simple explanation: Only listing creator can mint
        require(msg.sender == listing.creator, "Only creator can mint");

        // Simple explanation: Check listing has enough attestations
        require(canBeMinted(listingId), "Not enough attestations");

        // Simple explanation: Check listing is still active
        require(listing.state == ListingState.Active, "Listing must be active");

        uint256 tokenId = _nextTokenId++;

        // Simple explanation: Mint the NFT to the creator
        _safeMint(listing.creator, tokenId);

        // Simple explanation: Set the token URI to include listing data
        // _setTokenURI(tokenId, _generateTokenURI(listingId));
        _setTokenURI(tokenId, "");

        // Simple explanation: Update listing state to minted
        _setListingMinted(listingId);
    }

    // /// @dev Generates token URI with listing data
    // /// @param listingId The ID of the listing
    // function _generateTokenURI(
    //     uint256 listingId
    // ) internal view returns (string memory) {
    //     // For now return base URI, we'll implement proper URI generation later
    //     return _baseURI();
    // }

    /// @notice Generates the complete metadata URI for a token
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        // First verify token exists using parent implementation
        super.tokenURI(tokenId);

        // Get listing data for this token
        Listing memory listing = listings[tokenId];

        // Generate SVG image
        string memory image = Base64.encode(bytes(_generateSVG(listing)));

        // Create enhanced JSON metadata with strict formatting
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name":"',
                        listing.title,
                        '","description":"',
                        listing.details,
                        '","image":"data:image/svg+xml;base64,',
                        image,
                        '","attributes":[',
                        '{"trait_type":"Category","value":"',
                        listing.category,
                        '"}',
                        ',{"trait_type":"Attestations","value":',
                        _toString(listing.attestCount),
                        "}",
                        ',{"trait_type":"Creator Reputation","value":',
                        _toString(uint256(getReputation(listing.creator))),
                        "}",
                        ',{"trait_type":"Proof Count","value":',
                        _toString(listing.proofs.length),
                        "}",
                        ',{"trait_type":"Created","value":',
                        _toString(listing.createdAt),
                        "}",
                        '],"proofs":',
                        _arrayToJson(listing.proofs),
                        "}"
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    // HELPER FUNCTIONS

    function _baseURI() internal pure override returns (string memory) {
        return "https://uri";
    }

    /// @notice Retrieves a listing by its ID
    /// @dev Returns all fields of a listing
    /// @param listingId The ID of the listing to retrieve
    /// @return The complete listing struct
    function getListing(
        uint256 listingId
    ) public view returns (Listing memory) {
        return listings[listingId];
    }

    /// @notice Checks if a listing exists and is in active state
    /// @param listingId The ID of the listing to check
    /// @return bool indicating if listing is active
    function isListingActive(uint256 listingId) public view returns (bool) {
        return listings[listingId].state == ListingState.Active;
    }

    /// @notice Gets the total number of listings created
    /// @return The total number of listings
    function getTotalListings() public view returns (uint256) {
        return _nextListingId;
    }

    /// @notice Checks if a listing can be edited
    /// @dev A listing can only be edited if it's active and has no votes
    /// @param listingId The ID of the listing to check
    /// @return bool indicating if listing can be edited
    function canEditListing(uint256 listingId) public view returns (bool) {
        Listing storage listing = listings[listingId];
        return
            listing.state == ListingState.Active &&
            listing.attestCount == 0 &&
            listing.refuteCount == 0;
    }

    /// @notice Check if a listing can be minted (has enough attestations)
    /// @param listingId The listing ID to check
    /// @return bool indicating if listing can be minted
    function canBeMinted(uint256 listingId) public view returns (bool) {
        return listings[listingId].attestCount >= 2;
    }

    /// @notice Get all comments for a listing
    /// @param listingId The listing ID
    /// @return Array of comments
    function getListingComments(
        uint256 listingId
    ) public view returns (Comment[] memory) {
        return listingComments[listingId];
    }

    /// @dev Converts uint256 to string
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
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

    /// @dev Converts string array to JSON array
    function _arrayToJson(
        string[] memory arr
    ) internal pure returns (string memory) {
        bytes memory result = "[";
        for (uint i = 0; i < arr.length; i++) {
            if (i > 0) {
                result = abi.encodePacked(result, ",");
            }
            result = abi.encodePacked(result, '"', arr[i], '"');
        }
        result = abi.encodePacked(result, "]");
        return string(result);
    }

    /// @dev Updates reputation score for a user
    /// @param user Address of the user
    /// @param points Points to add (positive) or subtract (negative)
    /// @param reason Description of the change
    function _updateReputation(
        address user,
        int256 points,
        string memory reason
    ) internal {
        reputationScores[user] += points;
        emit ReputationChanged(user, points, reason);
    }

    /// @notice Get the reputation score for an address
    /// @param user The address to check
    /// @return The user's current reputation score
    function getReputation(address user) public view returns (int256) {
        return reputationScores[user];
    }

    /// @dev Generates SVG image for the NFT based on listing data
    function _generateSVG(
        Listing memory listing
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" width="500" height="500">',
                    "<style>text{font-family:sans-serif;}</style>",
                    '<rect width="100%" height="100%" fill="#1a1b1e"/>',
                    '<text x="50%" y="20%" text-anchor="middle" fill="white" font-size="24">',
                    listing.title,
                    "</text>",
                    '<text x="50%" y="30%" text-anchor="middle" fill="#888" font-size="16">',
                    listing.category,
                    "</text>",
                    '<text x="50%" y="50%" text-anchor="middle" fill="white" font-size="14">',
                    "Attestations: ",
                    _toString(listing.attestCount),
                    "</text>",
                    "</svg>"
                )
            );
    }

    // ADMIN FUNCTIONS

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // OVERIDE FUNCTIONS

    // The following functions are overrides required by Solidity.

    function _update(
        address to,
        uint256 tokenId,
        address auth
    )
        internal
        override(ERC721, ERC721Enumerable, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    // function tokenURI(
    //     uint256 tokenId
    // ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    //     return super.tokenURI(tokenId);
    // }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // EVENTS - these help frontend apps know when things happen

    /// @notice Emitted when a new listing is created
    /// @param id The ID of the new listing
    /// @param creator Address of the listing creator
    event ListingCreated(uint256 indexed id, address indexed creator);

    // Simple explanation: This event tells everyone when a listing's state changes
    /// @notice Emitted when a listing's state changes
    /// @param listingId The ID of the listing that changed
    /// @param newState The new state of the listing
    /// @param note Additional information about the state change
    event ListingStateChanged(
        uint256 indexed listingId,
        ListingState indexed newState,
        string note
    );

    /// @notice Emitted when a vote is cast
    event VoteCast(
        uint256 indexed listingId,
        address indexed voter,
        bool isAttest,
        string comment
    );

    /// @notice Emitted when a vote receives feedback
    event VoteFeedback(
        uint256 indexed listingId,
        address indexed voter,
        address indexed feedbackGiver,
        bool isUpvote
    );

    /// @notice Emitted when a new comment is created
    event CommentCreated(
        uint256 indexed listingId,
        uint256 indexed commentId,
        address indexed author,
        uint256 parentId
    );

    /// @notice Emitted when a comment receives a vote
    event CommentVoted(
        uint256 indexed commentId,
        address indexed voter,
        bool isUpvote
    );

    /// @notice Emitted when a user's reputation changes
    /// @param user Address of the user
    /// @param change Point change amount (positive or negative)
    /// @param reason Description of why the change occurred
    event ReputationChanged(address indexed user, int256 change, string reason);
}
