// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibAppStorage.sol";

contract CommentFacet {
    AppStorage internal s;

    // Event declarations
    event CommentCreated(
        uint256 indexed commentId,
        address indexed author,
        uint256 indexed entryId,
        string content
    );
    event CommentEdited(
        uint256 indexed commentId,
        address indexed author,
        string newContent
    );
    event CommentDeleted(uint256 indexed commentId, address indexed author);
    event CommentReplied(
        uint256 indexed parentCommentId,
        uint256 indexed replyCommentId,
        address indexed author
    );
    event CommentUpvoted(uint256 indexed commentId, address indexed voter);
    event CommentDownvoted(uint256 indexed commentId, address indexed voter);

    // Function to create a comment (either regular or vote-comment)
    function createComment(
        uint256 entryId,
        string memory content,
        uint256 parentId, // 0 if no parent comment (for root comments)
        bool isVoteComment, // true for vote-comment, false for regular comment
        uint256 voteId // Required only for vote-comments, can be 0 for regular comments
    ) external {
        uint256 newCommentId = s.nextCommentId++;
        Comment storage newComment = s.comments[newCommentId];

        newComment.id = newCommentId;
        newComment.author = msg.sender;
        newComment.content = content;
        newComment.timestamp = block.timestamp;
        newComment.parentId = parentId;
        newComment.entryId = entryId;
        newComment.voteId = voteId;
        newComment.isVoteComment = isVoteComment;

        // Add the comment to the correct storage (either entry or vote)
        if (isVoteComment) {
            s.commentsByVote[voteId].push(newCommentId);
        } else {
            s.commentsByEntry[entryId].push(newCommentId);
        }

        // Add the comment to the user's list of commented entries
        s.users[msg.sender].commentedEntries.push(entryId);

        emit CommentCreated(newCommentId, msg.sender, entryId, content);
    }

    // Function to edit a comment
    function editComment(uint256 commentId, string memory newContent) external {
        Comment storage comment = s.comments[commentId];

        require(
            comment.author == msg.sender,
            "Only the author can edit the comment"
        );
        require(bytes(newContent).length > 0, "Content cannot be empty");

        comment.content = newContent;
        comment.timestamp = block.timestamp;

        emit CommentEdited(commentId, msg.sender, newContent);
    }

    // Function to delete a comment
    function deleteComment(uint256 commentId) external {
        Comment storage comment = s.comments[commentId];

        require(
            comment.author == msg.sender,
            "Only the author can delete the comment"
        );

        // Deleting a comment will require shifting storage to avoid gaps, so we omit that for simplicity here
        delete s.comments[commentId];
        emit CommentDeleted(commentId, msg.sender);
    }

    // Function to reply to a comment
    function replyToComment(
        uint256 parentCommentId,
        string memory content
    ) external {
        Comment storage parentComment = s.comments[parentCommentId];
        uint256 newReplyId = s.nextCommentId++;

        Comment storage newReply = s.comments[newReplyId];

        newReply.id = newReplyId;
        newReply.author = msg.sender;
        newReply.content = content;
        newReply.timestamp = block.timestamp;
        newReply.parentId = parentCommentId;
        newReply.entryId = parentComment.entryId;
        newReply.voteId = parentComment.voteId;
        newReply.isVoteComment = parentComment.isVoteComment;

        // Add reply to the parent comment's replies
        s.repliesByComment[parentCommentId].push(newReplyId);

        emit CommentReplied(parentCommentId, newReplyId, msg.sender);
    }

    // Function to upvote a comment
    function upvoteComment(uint256 commentId) external {
        Comment storage comment = s.comments[commentId];

        // Check if the user has already upvoted or downvoted
        require(
            comment.addressToUpvotes[msg.sender].timestamp == 0,
            "Already upvoted this comment"
        );

        // Add the upvote
        comment.upvotes.push(
            CommentVote({
                voter: msg.sender,
                isUpvote: true,
                timestamp: block.timestamp
            })
        );

        comment.upvoteCount++;

        // Record upvote
        comment.addressToUpvotes[msg.sender] = CommentVote({
            voter: msg.sender,
            isUpvote: true,
            timestamp: block.timestamp
        });

        emit CommentUpvoted(commentId, msg.sender);
    }

    // Function to downvote a comment
    function downvoteComment(uint256 commentId) external {
        Comment storage comment = s.comments[commentId];

        // Check if the user has already upvoted or downvoted
        require(
            comment.addressToDownvotes[msg.sender].timestamp == 0,
            "Already downvoted this comment"
        );

        // Add the downvote
        comment.downvotes.push(
            CommentVote({
                voter: msg.sender,
                isUpvote: false,
                timestamp: block.timestamp
            })
        );

        comment.downvoteCount++;

        // Record downvote
        comment.addressToDownvotes[msg.sender] = CommentVote({
            voter: msg.sender,
            isUpvote: false,
            timestamp: block.timestamp
        });

        emit CommentDownvoted(commentId, msg.sender);
    }

    // View function to get comments for a specific entry
    function getCommentsForEntry(
        uint256 entryId
    ) external view returns (uint256[] memory) {
        return s.commentsByEntry[entryId];
    }
}
