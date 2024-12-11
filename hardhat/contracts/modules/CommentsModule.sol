// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../interfaces/IComments.sol";
import "../interfaces/IReputation.sol";
import "../interfaces/IListing.sol";
import "../interfaces/IErrors.sol";
import "hardhat/console.sol";

/// @title CommentsModule
/// @notice Implements commenting functionality for CAPOEP
/// @dev Handles both general comments and vote-comments with nested structure
contract CommentsModule is IComments, IErrors {
    // CUSTOM ERRORS
    error CommentDoesNotExist();
    error InvalidParentComment();
    error EmptyComment();
    error AlreadyVotedOnComment();
    error UnauthorizedVoteComment();
    error InvalidVoteCommentOperation();
    error TestError1();
    error TestError2();
    error TestError3();
    error TestError4();

    /// @dev Address of the main CAPOEP contract
    address private _capoepAddress;

    /// @dev Reference to the reputation module
    IReputation private _reputationModule;

    /// @dev Counter for generating unique comment IDs
    uint256 private _nextCommentId;

    /// @dev Maps listing IDs to arrays of general comments
    mapping(uint256 => Comment[]) private _listingComments;

    /// @dev Maps listing IDs to arrays of vote comments
    mapping(uint256 => Comment[]) private _voteComments;

    /// @dev Maps comment IDs to voter addresses to their vote status
    mapping(uint256 => mapping(address => bool)) private _commentVotes;

    /// @dev Maps comment IDs to their parent comments for efficient lookups
    mapping(uint256 => uint256) private _commentParents;

    /// @dev Maps vote IDs to their associated comment IDs
    mapping(uint256 => uint256) private _voteToComments;

    // EVENTS
    /// @notice Emitted when a vote comment is created
    event VoteCommentCreated(
        uint256 indexed listingId,
        uint256 indexed voteId,
        uint256 indexed commentId,
        address author
    );

    // CONSTRUCTOR
    constructor(address capoepAddress, IReputation reputationModule) {
        _capoepAddress = capoepAddress;
        _reputationModule = reputationModule;
        console.log("CommentsModule initialized with CAPOEP address:", capoepAddress);
        console.log("CommentsModule initialized with ReputationModule at:", address(reputationModule));
    }

    // MODIFIERS
    /// @dev Ensures listing is active
    modifier onlyActiveListing(uint256 listingId) {
        IListing listing = IListing(_capoepAddress);
        if (!listing.isListingActive(listingId)) revert ListingNotActive();
        _;
    }

    // CORE FUNCTIONS

    /// @inheritdoc IComments
    function addComment(
        uint256 listingId,
        string memory content,
        uint256 parentId
    ) external override onlyActiveListing(listingId) returns (uint256) {
        // Validate listing
        IListing listing = IListing(_capoepAddress);
        if (!listing.isListingActive(listingId)) revert ListingNotActive();

        // Check for empty comment
        if (bytes(content).length == 0) revert EmptyComment();

        // Validate parent comment if not root
        if (parentId != 0) {
            bool parentFound = false;
            Comment[] storage comments = _listingComments[listingId];
            for (uint i = 0; i < comments.length; i++) {
                if (comments[i].id == parentId) {
                    parentFound = true;
                    break;
                }
            }
            if (!parentFound) revert InvalidParentComment();
        }

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

        _listingComments[listingId].push(newComment);
        if (parentId != 0) {
            _commentParents[commentId] = parentId;
        }

        emit CommentCreated(listingId, commentId, msg.sender, parentId);

        return commentId;
    }

    /// @notice Creates a vote comment
    /// @dev Only called by the VotingModule when a vote is cast
    /// @param listingId The listing being voted on
    /// @param voteId The ID of the vote
    /// @param content The comment content
    function addVoteComment(
        uint256 listingId,
        uint256 voteId,
        string memory content
    ) external onlyActiveListing(listingId) returns (uint256) {
        // Validate listing
        IListing listing = IListing(_capoepAddress);
        if (!listing.isListingActive(listingId)) revert ListingNotActive();

        // Check for empty comment
        if (bytes(content).length == 0) revert EmptyComment();

        uint256 commentId = _nextCommentId++;

        Comment memory newComment = Comment({
            id: commentId,
            author: msg.sender,
            content: content,
            timestamp: block.timestamp,
            parentId: 0,
            upvotes: 0,
            downvotes: 0,
            isVoteComment: true
        });

        _voteComments[listingId].push(newComment);
        _voteToComments[voteId] = commentId;

        emit VoteCommentCreated(listingId, voteId, commentId, msg.sender);
        emit CommentCreated(listingId, commentId, msg.sender, 0);

        return commentId;
    }

    /// @inheritdoc IComments
    function voteOnComment(
        uint256 listingId,
        uint256 commentId,
        bool isUpvote
    ) external override onlyActiveListing(listingId) {
        // Validate listing
        IListing listing = IListing(_capoepAddress);
        if (!listing.isListingActive(listingId)) revert ListingNotActive();

        // Check comment exists
        bool found = false;
        address commentAuthor;

        // Check general comments
        Comment[] storage comments = _listingComments[listingId];
        for (uint i = 0; i < comments.length; i++) {
            if (comments[i].id == commentId) {
                if (_commentVotes[commentId][msg.sender]) revert AlreadyVotedOnComment();
                if (isUpvote) {
                    comments[i].upvotes++;
                } else {
                    comments[i].downvotes++;
                }
                commentAuthor = comments[i].author;
                found = true;
                break;
            }
        }

        // Check vote comments if not found
        if (!found) {
            Comment[] storage voteComments = _voteComments[listingId];
            for (uint i = 0; i < voteComments.length; i++) {
                if (voteComments[i].id == commentId) {
                    if (_commentVotes[commentId][msg.sender]) revert AlreadyVotedOnComment();
                    if (isUpvote) {
                        voteComments[i].upvotes++;
                    } else {
                        voteComments[i].downvotes++;
                    }
                    commentAuthor = voteComments[i].author;
                    found = true;
                    break;
                }
            }
        }

        if (!found) revert CommentDoesNotExist();

        _commentVotes[commentId][msg.sender] = true;
        
        // Update reputation
        _reputationModule.updateReputationFromCommentFeedback(
            commentAuthor,
            isUpvote
        );

        emit CommentVoted(commentId, msg.sender, isUpvote);
    }

    // VIEW FUNCTIONS

    /// @inheritdoc IComments
    function getListingComments(
        uint256 listingId
    ) external view override returns (Comment[] memory) {
        return _listingComments[listingId];
    }

    /// @notice Get all vote comments for a listing
    /// @param listingId The listing ID
    /// @return Array of vote comments
    function getVoteComments(
        uint256 listingId
    ) external view returns (Comment[] memory) {
        return _voteComments[listingId];
    }

    /// @notice Retrieves a comment by its index in the listing's comments
    /// @param listingId The ID of the listing
    /// @param commentIndex The index of the comment in the listing's comments array
    /// @return The comment details
    function getCommentByIndex(
        uint256 listingId,
        uint256 commentIndex
    ) external view returns (Comment memory) {
        Comment[] storage comments = _listingComments[listingId];
        if (commentIndex >= comments.length) revert CommentDoesNotExist();
        return comments[commentIndex];
    }

    /// @notice Retrieves a specific comment by its ID
    /// @param listingId The ID of the listing
    /// @param commentId The unique ID of the comment
    /// @return The comment details
    function getCommentById(
        uint256 listingId,
        uint256 commentId
    ) external view returns (Comment memory) {
        Comment[] storage comments = _listingComments[listingId];
        for (uint i = 0; i < comments.length; i++) {
            if (comments[i].id == commentId) {
                return comments[i];
            }
        }
        revert CommentDoesNotExist();
    }

    /// @notice Get a comment by its ID
    /// @param listingId The listing ID
    /// @param commentId The comment ID
    /// @return The comment if found
    function getComment(
        uint256 listingId,
        uint256 commentId
    ) external view returns (Comment memory) {
        // Check general comments
        Comment[] memory comments = _listingComments[listingId];
        for (uint i = 0; i < comments.length; i++) {
            if (comments[i].id == commentId) {
                return comments[i];
            }
        }

        // Check vote comments
        Comment[] memory voteComments = _voteComments[listingId];
        for (uint i = 0; i < voteComments.length; i++) {
            if (voteComments[i].id == commentId) {
                return voteComments[i];
            }
        }

        revert CommentDoesNotExist();
    }

    /// @notice Get the comment associated with a vote
    /// @param voteId The vote ID
    /// @return The associated comment ID
    function getVoteComment(uint256 voteId) external view returns (uint256) {
        return _voteToComments[voteId];
    }

    /// @notice Get all child comments of a parent comment
    /// @param listingId The listing ID
    /// @param parentId The parent comment ID
    /// @return Array of child comments
    function getChildComments(
        uint256 listingId,
        uint256 parentId
    ) external view returns (Comment[] memory) {
        Comment[] memory allComments = _listingComments[listingId];
        uint256 childCount = 0;

        // Count children first
        for (uint i = 0; i < allComments.length; i++) {
            if (allComments[i].parentId == parentId) {
                childCount++;
            }
        }

        // Create and fill children array
        Comment[] memory children = new Comment[](childCount);
        uint256 currentIndex = 0;
        for (uint i = 0; i < allComments.length; i++) {
            if (allComments[i].parentId == parentId) {
                children[currentIndex] = allComments[i];
                currentIndex++;
            }
        }

        return children;
    }

    /// @notice Get the CAPOEP contract address
    /// @return The address of the CAPOEP contract
    function getCapoepAddress() external view returns (address) {
        return _capoepAddress;
    }
}
