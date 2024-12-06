// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../interfaces/IComments.sol";

/// @title CommentsModule
/// @notice Implements commenting functionality for CAPOEP
/// @dev Handles comment creation, nested comments, and voting
contract CommentsModule is IComments {
    // CUSTOM ERRORS

    error EmptyComment();
    error AlreadyVotedOnComment();
    error CommentNotFound();
    error ListingMinted();

    // STATE VARIABLES

    /// @dev Counter for generating unique comment IDs
    uint256 private _nextCommentId;

    /// @dev Maps listing IDs to arrays of comments
    mapping(uint256 => Comment[]) private _listingComments;

    /// @dev Maps comment IDs to voter addresses to their vote status
    mapping(uint256 => mapping(address => bool)) private _commentVotes;

    // CORE FUNCTIONS

    /// @inheritdoc IComments
    function addComment(
        uint256 listingId,
        string memory content,
        uint256 parentId
    ) external override returns (uint256) {
        if (bytes(content).length == 0) revert EmptyComment();

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

        emit CommentCreated(listingId, commentId, msg.sender, parentId);

        return commentId;
    }

    /// @inheritdoc IComments
    function voteOnComment(
        uint256 listingId,
        uint256 commentId,
        bool isUpvote
    ) external override {
        Comment[] storage comments = _listingComments[listingId];
        bool found = false;

        for (uint i = 0; i < comments.length; i++) {
            if (comments[i].id == commentId) {
                if (_commentVotes[commentId][msg.sender])
                    revert AlreadyVotedOnComment();

                if (isUpvote) {
                    comments[i].upvotes++;
                } else {
                    comments[i].downvotes++;
                }

                _commentVotes[commentId][msg.sender] = true;
                emit CommentVoted(commentId, msg.sender, isUpvote);
                found = true;
                break;
            }
        }

        if (!found) revert CommentNotFound();
    }

    // VIEW FUNCTIONS

    /// @inheritdoc IComments
    function getListingComments(
        uint256 listingId
    ) external view override returns (Comment[] memory) {
        return _listingComments[listingId];
    }
}
