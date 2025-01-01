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
    event CommentUnvoted(uint256 indexed commentId, address indexed voter);

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
            s.commentIndexInVote[commentId] = s.commentsByVotes[voteId].length;
            s.commentsByVotes[voteId].push(commentId);
        } else {
            s.commentIndexInEntry[commentId] = s
                .commentsByEntries[entryId]
                .length;
            s.commentsByEntries[entryId].push(commentId);
        }

        // Add the comment to the list of replies if it's a reply
        if (parentId != 0) {
            s.commentIndexInReplies[commentId] = s
                .repliesByComments[parentId]
                .length;
            s.repliesByComments[parentId].push(commentId);
        }

        // Add the comment to the user's list of commented entries
        s.userCommentIndex[msg.sender][commentId] = s
            .users[msg.sender]
            .commentedEntries
            .length;
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

    // Function to delete a comment
    function deleteComment(uint256 commentId) external {
        // Check if the comment exists
        require(s.comments[commentId].id != 0, "Comment does not exist");

        Comment storage comment = s.comments[commentId];

        // Check if the caller is the author of the comment
        require(
            comment.author == msg.sender,
            "Only the author can delete the comment"
        );

        // Remove the comment from the parent's replies (if it's a reply)
        if (comment.parentId != 0) {
            uint256[] storage parentReplies = s.repliesByComments[
                comment.parentId
            ];
            uint256 index = s.commentIndexInReplies[commentId];

            // Swap and pop
            if (index < parentReplies.length - 1) {
                parentReplies[index] = parentReplies[parentReplies.length - 1];
                s.commentIndexInReplies[parentReplies[index]] = index;
            }
            parentReplies.pop();
        }

        // Remove the comment from the entry's comments (if it's a general comment)
        if (!comment.isVoteComment) {
            uint256[] storage entryComments = s.commentsByEntries[
                comment.entryId
            ];
            uint256 index = s.commentIndexInEntry[commentId];

            // Swap and pop
            if (index < entryComments.length - 1) {
                entryComments[index] = entryComments[entryComments.length - 1];
                s.commentIndexInEntry[entryComments[index]] = index;
            }
            entryComments.pop();
        }

        // Remove the comment from the vote's comments (if it's a vote-comment)
        if (comment.isVoteComment) {
            uint256[] storage voteComments = s.commentsByVotes[comment.voteId];
            uint256 index = s.commentIndexInVote[commentId];

            // Swap and pop
            if (index < voteComments.length - 1) {
                voteComments[index] = voteComments[voteComments.length - 1];
                s.commentIndexInVote[voteComments[index]] = index;
            }
            voteComments.pop();
        }

        // Remove the comment from the user's commented entries
        uint256[] storage userComments = s.users[msg.sender].commentedEntries;
        uint256 index = s.userCommentIndex[msg.sender][commentId];

        // Swap and pop
        if (index < userComments.length - 1) {
            userComments[index] = userComments[userComments.length - 1];
            s.userCommentIndex[msg.sender][userComments[index]] = index;
        }
        userComments.pop();

        // Delete the comment from storage
        delete s.comments[commentId];

        emit CommentDeleted(commentId, msg.sender);
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

            // Remove the downvote from the downvotes array
            uint256 index = s.downvoteIndex[commentId];
            if (index < comment.downvotes.length - 1) {
                comment.downvotes[index] = comment.downvotes[
                    comment.downvotes.length - 1
                ];
                s.downvoteIndex[commentId] = index; // Update the index for the moved downvote
            }
            comment.downvotes.pop();

            delete comment.addressToDownvotes[msg.sender];
        }

        // Add the upvote
        s.upvoteIndex[commentId] = comment.upvotes.length;

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

            // Remove the downvote from the downvotes array
            uint256 index = s.upvoteIndex[commentId];
            if (index < comment.upvotes.length - 1) {
                comment.upvotes[index] = comment.upvotes[
                    comment.upvotes.length - 1
                ];
                s.upvoteIndex[commentId] = index; // Update the index for the moved upvote
            }
            comment.upvotes.pop();

            delete comment.addressToUpvotes[msg.sender];
        }

        // Add the downvote
        s.downvoteIndex[commentId] = comment.downvotes.length;
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

    // Function to unvote a comment
    function unvoteComment(uint256 commentId) external {
        // Check if the comment exists
        require(s.comments[commentId].id != 0, "Comment does not exist");

        Comment storage comment = s.comments[commentId];

        // Check if the user has upvoted or downvoted the comment
        require(
            comment.addressToUpvotes[msg.sender].timestamp != 0 ||
                comment.addressToDownvotes[msg.sender].timestamp != 0,
            "User has not voted on this comment"
        );

        // Remove the upvote if it exists
        if (comment.addressToUpvotes[msg.sender].timestamp != 0) {
            // Decrement the upvote count
            comment.upvoteCount--;

            // Remove the upvote from the upvotes array
            uint256 index = s.upvoteIndex[commentId];
            if (index < comment.upvotes.length - 1) {
                comment.upvotes[index] = comment.upvotes[
                    comment.upvotes.length - 1
                ];
                s.upvoteIndex[commentId] = index; // Update the index for the moved upvote
            }
            comment.upvotes.pop();

            // Remove the upvote from the addressToUpvotes mapping
            delete comment.addressToUpvotes[msg.sender];
        }

        // Remove the downvote if it exists
        if (comment.addressToDownvotes[msg.sender].timestamp != 0) {
            // Decrement the downvote count
            comment.downvoteCount--;

            // Remove the downvote from the downvotes array
            uint256 index = s.downvoteIndex[commentId];
            if (index < comment.downvotes.length - 1) {
                comment.downvotes[index] = comment.downvotes[
                    comment.downvotes.length - 1
                ];
                s.downvoteIndex[commentId] = index;
            }
            comment.downvotes.pop();

            // Remove the downvote from the addressToDownvotes mapping
            delete comment.addressToDownvotes[msg.sender];
        }

        // Remove the comment from the user's votedOnComments list
        uint256[] storage userVotedComments = s
            .users[msg.sender]
            .votedOnComments;
        for (uint256 i = 0; i < userVotedComments.length; i++) {
            if (userVotedComments[i] == commentId) {
                // Swap and pop
                userVotedComments[i] = userVotedComments[
                    userVotedComments.length - 1
                ];
                userVotedComments.pop();
                break;
            }
        }

        // Mark the user as not having voted on this comment
        delete s.users[msg.sender].hasVotedComment[commentId];

        emit CommentUnvoted(commentId, msg.sender);
    }

    // // Get a comment by ID
    // function getComment(
    //     uint256 commentId
    // ) external view returns (Comment memory) {
    //     return s.comments[commentId];
    // }

    // Get all general comments for a listing
    // function getCommentsByEntry(
    //     uint256 entryId
    // ) external view returns (uint256[] memory) {
    //     return s.commentsByEntries[entryId];
    // }

    // // Get all Vote-Comments for a vote
    // function getCommentsByVote(
    //     uint256 voteId
    // ) external view returns (uint256[] memory) {
    //     return s.commentsByVotes[voteId];
    // }

    // // Get all replies to a comment
    // function getRepliesByComment(
    //     uint256 commentId
    // ) external view returns (uint256[] memory) {
    //     return s.repliesByComments[commentId];
    // }
}
