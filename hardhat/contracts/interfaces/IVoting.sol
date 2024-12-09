// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @title IVoting Interface
/// @notice Interface for the voting functionality of CAPOEP
/// @dev Implements attestation and refutation voting system
interface IVoting {
    // STRUCTS
    
    /// @dev Struct to represent a vote
    struct Vote {
        bool isAttest; // true for attestation, false for refutation
        string comment; // Required comment explaining the vote
        uint256 timestamp; // When the vote was cast
        uint256 upvotes; // Number of upvotes this vote has received
        uint256 downvotes; // Number of downvotes this vote has received
    }

    /// @dev Struct to represent vote counts
    struct VoteCount {
        uint256 attestCount;
        uint256 contestCount;
    }

    // EVENTS
    
    /// @notice Emitted when a new vote is cast
    /// @param listingId The ID of the listing being voted on
    /// @param voter Address of the voter
    /// @param isAttest Whether this is an attestation (true) or refutation (false)
    /// @param comment The explanation provided with the vote
    event VoteCast(
        uint256 indexed listingId,
        address indexed voter,
        bool isAttest,
        string comment
    );

    /// @notice Emitted when a vote receives feedback
    /// @param listingId The listing ID
    /// @param voter The original voter's address
    /// @param feedbackGiver Address of the user giving feedback
    /// @param isUpvote Whether this is an upvote (true) or downvote (false)
    event VoteFeedback(
        uint256 indexed listingId,
        address indexed voter,
        address indexed feedbackGiver,
        bool isUpvote
    );

    // CORE FUNCTIONS
    
    /// @notice Cast a vote on a listing
    /// @dev Can only vote once per listing
    /// @param listingId The ID of the listing to vote on
    /// @param isAttest True for attestation, false for refutation
    /// @param comment Required explanation for the vote
    function castVote(
        uint256 listingId,
        bool isAttest,
        string memory comment
    ) external;

    /// @notice Give feedback on an existing vote
    /// @dev Updates the vote's upvote or downvote count
    /// @param listingId The listing ID
    /// @param voter The address of the original voter
    /// @param isUpvote True for upvote, false for downvote
    function giveVoteFeedback(
        uint256 listingId,
        address voter,
        bool isUpvote
    ) external;

    // VIEW FUNCTIONS
    
    /// @notice Retrieves the vote count for a specific listing
    /// @param listingId The ID of the listing
    /// @return The vote count structure
    function getVoteCount(uint256 listingId) external view returns (VoteCount memory);

    /// @notice Retrieves the list of voters for a specific listing
    /// @param listingId The ID of the listing
    /// @return An array of voter addresses
    function getVoters(uint256 listingId) external view returns (address[] memory);

    /// @notice Get a specific vote for a listing
    /// @param listingId The ID of the listing
    /// @param voter The address of the voter
    /// @return Vote struct containing the vote details
    function getVote(uint256 listingId, address voter) external view returns (Vote memory);
}
