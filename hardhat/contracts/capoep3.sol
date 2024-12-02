// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CAPOE is ERC721 {
    using Counters for Counters.Counter;

    Counters.Counter private _listingIds;
    Counters.Counter private _tokenIds;

    enum EducationCategory {
        STUDENT,              // Learners showing proof of learning
        EDUCATOR,             // Teachers/professors showing teaching experience
        CONTENT_CREATOR,      // Educational content creators
        INSTITUTION,          // Educational institutions
        RESEARCHER,           // Educational researchers
        MENTOR,              // Mentors/coaches
        COMMUNITY_EDUCATOR    // Workshop leaders, community teachers
    }

    struct Listing {
        string title;
        string details;
        string[] proofs;
        address creator;
        bool minted;
        uint256 createdAt;
        EducationCategory category;
    }

    struct Vote {
        address voter;
        bool isUpvote;
        string comment;
        uint256 timestamp;
    }

    struct Comment {
        uint256 commentId;
        address commenter;
        string content;
        int256 voteCount;
        uint256 timestamp;
        uint256 parentId;
        uint256[] childIds;
    }

    struct BatchVote {
        uint256 listingId;
        bool isUpvote;
        string comment;
    }

    struct BatchComment {
        uint256 listingId;
        string content;
        uint256 parentId;
    }

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => Vote[]) public listingVotes;
    mapping(uint256 => Comment[]) public listingComments;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public commentVotes;

    // Add reputation mapping
    mapping(address => int256) public userReputation;

    // Add category-based mapping for discovery
    mapping(EducationCategory => uint256[]) public categoryListings;

    event ListingCreated(
        uint256 indexed listingId,
        address indexed creator,
        EducationCategory indexed category
    );
    event ListingMinted(uint256 indexed listingId, uint256 indexed tokenId, address indexed creator);
    event VoteSubmitted(uint256 indexed listingId, address indexed voter, bool isUpvote);
    event CommentAdded(uint256 indexed listingId, uint256 commentId, address indexed commenter, uint256 parentId);
    event CommentVoted(uint256 indexed listingId, uint256 indexed commentId, address indexed voter, bool isUpvote);
    event BatchVotesSubmitted(address indexed voter, uint256[] listingIds);
    event BatchCommentsAdded(address indexed commenter, uint256[] listingIds);
    event ReputationChanged(address indexed user, int256 change, int256 newTotal);

    constructor() ERC721("Community Attested Proof of Education", "CAPOE") {}

    function createListing(
        string memory title,
        string memory details,
        string[] memory proofs,
        EducationCategory category
    ) external {
        require(bytes(title).length > 0, "Title cannot be empty");
        require(bytes(details).length > 0, "Details cannot be empty");
        require(proofs.length > 0, "Must provide at least one proof");

        uint256 listingId = _listingIds.current();
        _listingIds.increment();

        listings[listingId] = Listing({
            title: title,
            details: details,
            proofs: proofs,
            creator: msg.sender,
            minted: false,
            createdAt: block.timestamp,
            category: category
        });

        // Add to category mapping for discovery
        categoryListings[category].push(listingId);

        emit ListingCreated(listingId, msg.sender, category);
    }

    function mintListing(uint256 listingId) external {
        require(listings[listingId].creator == msg.sender, "Only creator can mint");
        require(!listings[listingId].minted, "Already minted");
        require(listings[listingId].creator != address(0), "Listing does not exist");

        uint256 tokenId = _tokenIds.current();
        _tokenIds.increment();

        _safeMint(msg.sender, tokenId);
        listings[listingId].minted = true;

        emit ListingMinted(listingId, tokenId, msg.sender);
    }

    function submitVote(
        uint256 listingId,
        bool isUpvote,
        string memory comment
    ) external {
        require(listings[listingId].creator != address(0), "Listing does not exist");
        require(bytes(comment).length > 0, "Must provide a comment with vote");
        require(!hasVoted[listingId][msg.sender], "Already voted on this listing");

        listingVotes[listingId].push(Vote({
            voter: msg.sender,
            isUpvote: isUpvote,
            comment: comment,
            timestamp: block.timestamp
        }));

        // Update reputation for listing creator
        address creator = listings[listingId].creator;
        int256 reputationChange = isUpvote ? 1 : -1;
        userReputation[creator] += reputationChange;

        hasVoted[listingId][msg.sender] = true;
        emit VoteSubmitted(listingId, msg.sender, isUpvote);
        emit ReputationChanged(creator, reputationChange, userReputation[creator]);
    }

    function addComment(
        uint256 listingId, 
        string memory content,
        uint256 parentId
    ) external {
        require(listings[listingId].creator != address(0), "Listing does not exist");
        require(bytes(content).length > 0, "Comment cannot be empty");
        
        if (parentId != 0) {
            require(parentId < listingComments[listingId].length, "Parent comment does not exist");
        }

        uint256 commentId = listingComments[listingId].length;
        
        listingComments[listingId].push(Comment({
            commentId: commentId,
            commenter: msg.sender,
            content: content,
            voteCount: 0,
            timestamp: block.timestamp,
            parentId: parentId,
            childIds: new uint256[](0)
        }));

        if (parentId != 0) {
            listingComments[listingId][parentId].childIds.push(commentId);
        }

        emit CommentAdded(listingId, commentId, msg.sender, parentId);
    }

    function voteOnComment(
        uint256 listingId,
        uint256 commentId,
        bool isUpvote
    ) external {
        require(listings[listingId].creator != address(0), "Listing does not exist");
        require(commentId < listingComments[listingId].length, "Comment does not exist");
        require(!commentVotes[listingId][commentId][msg.sender], "Already voted on this comment");

        Comment storage comment = listingComments[listingId][commentId];
        comment.voteCount += isUpvote ? 1 : -1;

        // Update reputation for comment author
        address commenter = comment.commenter;
        int256 reputationChange = isUpvote ? 1 : -1;
        userReputation[commenter] += reputationChange;

        commentVotes[listingId][commentId][msg.sender] = true;
        emit CommentVoted(listingId, commentId, msg.sender, isUpvote);
        emit ReputationChanged(commenter, reputationChange, userReputation[commenter]);
    }

    function submitBatchVotes(BatchVote[] calldata batchVotes) external {
        require(batchVotes.length > 0, "Empty batch");
        require(batchVotes.length <= 10, "Batch too large");

        uint256[] memory listingIds = new uint256[](batchVotes.length);

        for (uint256 i = 0; i < batchVotes.length; i++) {
            BatchVote calldata vote = batchVotes[i];
            require(listings[vote.listingId].creator != address(0), "Listing does not exist");
            require(!hasVoted[vote.listingId][msg.sender], "Already voted on listing");
            require(bytes(vote.comment).length > 0, "Must provide a comment");

            listingVotes[vote.listingId].push(Vote({
                voter: msg.sender,
                isUpvote: vote.isUpvote,
                comment: vote.comment,
                timestamp: block.timestamp
            }));

            hasVoted[vote.listingId][msg.sender] = true;
            listingIds[i] = vote.listingId;
            emit VoteSubmitted(vote.listingId, msg.sender, vote.isUpvote);

            // Update reputation
            address creator = listings[vote.listingId].creator;
            int256 reputationChange = vote.isUpvote ? 1 : -1;
            userReputation[creator] += reputationChange;
            emit ReputationChanged(creator, reputationChange, userReputation[creator]);
        }

        emit BatchVotesSubmitted(msg.sender, listingIds);
    }

    function submitBatchComments(BatchComment[] calldata batchComments) external {
        require(batchComments.length > 0, "Empty batch");
        require(batchComments.length <= 10, "Batch too large");

        uint256[] memory listingIds = new uint256[](batchComments.length);

        for (uint256 i = 0; i < batchComments.length; i++) {
            BatchComment calldata comment = batchComments[i];
            require(listings[comment.listingId].creator != address(0), "Listing does not exist");
            require(bytes(comment.content).length > 0, "Comment cannot be empty");

            if (comment.parentId != 0) {
                require(comment.parentId < listingComments[comment.listingId].length, "Parent comment does not exist");
            }

            uint256 commentId = listingComments[comment.listingId].length;
            
            listingComments[comment.listingId].push(Comment({
                commentId: commentId,
                commenter: msg.sender,
                content: comment.content,
                voteCount: 0,
                timestamp: block.timestamp,
                parentId: comment.parentId,
                childIds: new uint256[](0)
            }));

            if (comment.parentId != 0) {
                listingComments[comment.listingId][comment.parentId].childIds.push(commentId);
            }

            listingIds[i] = comment.listingId;
            emit CommentAdded(comment.listingId, commentId, msg.sender, comment.parentId);
        }

        emit BatchCommentsAdded(msg.sender, listingIds);
    }

    function getCommentThread(uint256 listingId, uint256 commentId) external view returns (
        Comment memory rootComment,
        Comment[] memory replies
    ) {
        require(commentId < listingComments[listingId].length, "Comment does not exist");
        
        rootComment = listingComments[listingId][commentId];
        uint256 replyCount = rootComment.childIds.length;
        replies = new Comment[](replyCount);
        
        for (uint256 i = 0; i < replyCount; i++) {
            replies[i] = listingComments[listingId][rootComment.childIds[i]];
        }
    }

    // View functions
    function getListing(uint256 listingId) external view returns (Listing memory) {
        require(listings[listingId].creator != address(0), "Listing does not exist");
        return listings[listingId];
    }

    function getListingVotes(uint256 listingId) external view returns (Vote[] memory) {
        return listingVotes[listingId];
    }

    function getListingComments(uint256 listingId) external view returns (Comment[] memory) {
        return listingComments[listingId];
    }

    function getListingVoteCount(uint256 listingId) external view returns (uint256 upvotes, uint256 downvotes) {
        Vote[] memory votes = listingVotes[listingId];
        for (uint i = 0; i < votes.length; i++) {
            if (votes[i].isUpvote) {
                upvotes++;
            } else {
                downvotes++;
            }
        }
    }

    // Add view function for reputation
    function getUserReputation(address user) external view returns (int256) {
        return userReputation[user];
    }

    // Add discovery functions
    function getListingsByCategory(EducationCategory category) 
        external 
        view 
        returns (uint256[] memory) 
    {
        return categoryListings[category];
    }

    function getCategoryName(EducationCategory category) 
        external 
        pure 
        returns (string memory) 
    {
        if (category == EducationCategory.STUDENT) return "Student";
        if (category == EducationCategory.EDUCATOR) return "Educator";
        if (category == EducationCategory.CONTENT_CREATOR) return "Content Creator";
        if (category == EducationCategory.INSTITUTION) return "Institution";
        if (category == EducationCategory.RESEARCHER) return "Researcher";
        if (category == EducationCategory.MENTOR) return "Mentor";
        if (category == EducationCategory.COMMUNITY_EDUCATOR) return "Community Educator";
        revert("Invalid category");
    }
}
