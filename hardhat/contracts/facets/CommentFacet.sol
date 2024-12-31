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
        string content,
        bool isVoteComment
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

    // Function to create a comment (either general or vote-comment)
    function createComment(
        uint256 entryId,
        string memory content,
        uint256 parentId, // 0 if no parent comment (for root comments)
        bool isVoteComment, // true for vote-comment, false for regular comment
        uint256 voteId // Required only for vote-comments, can be 0 for regular comments
    ) external {
        // Check if the entry exists
        require(s.entries[entryId].id != 0, "Entry does not exist");

        // For Vote-Comments, ensure the vote exists
        if (isVoteComment) {
            require(s.votes[voteId].voter != address(0), "Vote does not exist");
        }

        // Check if content is not empty
        require(bytes(content).length > 0, "Content cannot be empty");

        uint256 commentId = s.nextCommentId;
        s.nextCommentId++;

        Comment storage comment = s.comments[commentId];

        comment.id = commentId;
        comment.isVoteComment = isVoteComment;
        comment.author = msg.sender;
        comment.content = content;
        comment.timestamp = block.timestamp;
        comment.parentId = parentId;
        comment.entryId = entryId;
        comment.voteId = voteId;
        comment.replies = new uint256[](0);
        comment.upvotes = new CommentVote[](0);
        comment.downvotes = new CommentVote[](0);
        comment.upvoteCount = 0;
        comment.downvoteCount = 0;

        // Add the comment to the correct storage (either vote-comments or general comments)
        if (isVoteComment) {
            s.commentsByVotes[voteId].push(commentId);
        } else {
            s.commentsByEntries[entryId].push(commentId);
        }

        // Add the comment to the list of replies if it's a reply
        if (parentId != 0) {
            s.repliesByComments[parentId].push(commentId);
        }

        // Add the comment to the user's list of commented entries
        s.users[msg.sender].commentedEntries.push(entryId);

        emit CommentCreated(
            commentId,
            msg.sender,
            entryId,
            content,
            isVoteComment
        );
    }

    // Function to edit a comment
    function editComment(uint256 commentId, string memory newContent) external {
        // Check if the comment exists
        require(s.comments[commentId].id != 0, "Comment does not exist");

        Comment storage comment = s.comments[commentId];

        // Check if the comment author is the sender
        require(
            comment.author == msg.sender,
            "Only the author can edit the comment"
        );

        // Check if content is not empty
        require(bytes(newContent).length > 0, "Content cannot be empty");

        comment.content = newContent;
        comment.editedAt = block.timestamp; // Update the edited timestamp

        emit CommentEdited(commentId, msg.sender, newContent);
    }

    // Function to reply to a comment
    function replyToComment(
        uint256 parentCommentId,
        string memory content
    ) external {
        // Validate parent comment exists
        require(
            s.comments[parentCommentId].id != 0,
            "Parent comment does not exist"
        );

        // Check if content is not empty
        require(bytes(content).length > 0, "Content cannot be empty");

        Comment storage parentComment = s.comments[parentCommentId];
        uint256 replyId = s.nextCommentId++;

        Comment storage reply = s.comments[replyId];

        // replies cant be vote comments
        reply.id = replyId;
        reply.isVoteComment = false;
        reply.author = msg.sender;
        reply.content = content;
        reply.timestamp = block.timestamp;
        reply.parentId = parentCommentId;
        reply.entryId = parentComment.entryId;
        reply.voteId = 0;
        reply.replies = new uint256[](0);
        reply.upvotes = new CommentVote[](0);
        reply.downvotes = new CommentVote[](0);
        reply.upvoteCount = 0;
        reply.downvoteCount = 0;

        // Add the reply to the parent comment's replies
        parentComment.replies.push(replyId);

        // Add the comment to the user's list of commented entries
        s.users[msg.sender].commentedEntries.push(parentComment.entryId);

        // Add the reply to the list of replies
        s.repliesByComments[parentCommentId].push(replyId);

        emit CommentReplied(parentCommentId, replyId, msg.sender);
    }

    // Function to upvote a comment
    function upvoteComment(uint256 commentId) external {
        Comment storage comment = s.comments[commentId];

        // Check if the user has already upvoted or downvoted
        require(
            comment.addressToUpvotes[msg.sender].timestamp == 0,
            "Already upvoted this comment"
        );

        // Remove existing downvote if any
        if (comment.addressToDownvotes[msg.sender].timestamp != 0) {
            comment.downvoteCount--;
            delete comment.addressToDownvotes[msg.sender];
        }

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

        // Record that the user has voted on this comment
        if (!s.users[msg.sender].hasVotedComment[commentId]) {
            s.users[msg.sender].hasVotedComment[commentId] = true;
            s.users[msg.sender].votedOnComments.push(commentId);
        }
        emit CommentUpvoted(commentId, msg.sender);
    }

    // Function to downvote a comment
    function downvoteComment(uint256 commentId) external {
        // Check if the comment exists
        require(s.comments[commentId].id != 0, "Comment does not exist");

        Comment storage comment = s.comments[commentId];

        // Check if the user has already upvoted or downvoted
        require(
            comment.addressToDownvotes[msg.sender].timestamp == 0,
            "Already downvoted this comment"
        );

        // Remove existing upvote if any
        if (comment.addressToUpvotes[msg.sender].timestamp != 0) {
            comment.upvoteCount--;
            delete comment.addressToUpvotes[msg.sender];
        }

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

        // Record that the user has voted on this comment
        if (!s.users[msg.sender].hasVotedComment[commentId]) {
            s.users[msg.sender].hasVotedComment[commentId] = true;
            s.users[msg.sender].votedOnComments.push(commentId);
        }

        emit CommentDownvoted(commentId, msg.sender);
    }

    // // Get a comment by ID
    // function getComment(
    //     uint256 commentId
    // ) external view returns (Comment memory) {
    //     return s.comments[commentId];
    // }

    // Get all general comments for a listing
    function getCommentsByEntry(
        uint256 entryId
    ) external view returns (uint256[] memory) {
        return s.commentsByEntries[entryId];
    }

    // Get all Vote-Comments for a vote
    function getCommentsByVote(
        uint256 voteId
    ) external view returns (uint256[] memory) {
        return s.commentsByVotes[voteId];
    }

    // Get all replies to a comment
    function getRepliesByComment(
        uint256 commentId
    ) external view returns (uint256[] memory) {
        return s.repliesByComments[commentId];
    }
}
