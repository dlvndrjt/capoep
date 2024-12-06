// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @title IComments Interface
/// @notice Interface for the commenting functionality of CAPOEP
/// @dev Implements nested commenting system with voting
interface IComments {
    // STRUCTS

    /// @notice Structure for storing comment information
    /// @dev Supports nested comments and voting functionality
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

    // EVENTS

    /// @notice Emitted when a new comment is created
    /// @param listingId The ID of the listing being commented on
    /// @param commentId The ID of the new comment
    /// @param author Address of the comment author
    /// @param parentId ID of parent comment (0 for top-level)
    event CommentCreated(
        uint256 indexed listingId,
        uint256 indexed commentId,
        address indexed author,
        uint256 parentId
    );

    /// @notice Emitted when a comment receives a vote
    /// @param commentId The ID of the comment
    /// @param voter Address of the voter
    /// @param isUpvote Whether this is an upvote (true) or downvote (false)
    event CommentVoted(
        uint256 indexed commentId,
        address indexed voter,
        bool isUpvote
    );

    // CORE FUNCTIONS

    /// @notice Add a comment to a listing
    /// @param listingId The ID of the listing to comment on
    /// @param content The comment content
    /// @param parentId ID of parent comment (0 for top-level)
    /// @return commentId The ID of the created comment
    function addComment(
        uint256 listingId,
        string memory content,
        uint256 parentId
    ) external returns (uint256);

    /// @notice Vote on an existing comment
    /// @param listingId The listing ID
    /// @param commentId The comment ID
    /// @param isUpvote True for upvote, false for downvote
    function voteOnComment(
        uint256 listingId,
        uint256 commentId,
        bool isUpvote
    ) external;

    // VIEW FUNCTIONS

    /// @notice Get all comments for a listing
    /// @param listingId The listing ID
    /// @return Array of comments
    function getListingComments(
        uint256 listingId
    ) external view returns (Comment[] memory);
}
