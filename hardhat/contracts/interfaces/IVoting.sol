// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @title IVoting Interface
/// @notice Interface for the voting functionality of CAPOEP
/// @dev Handles attestations and refutations with required comments
interface IVoting {
    // EVENTS
    event VoteCast(
        uint256 indexed listingId,
        address indexed voter,
        bool isAttestation,
        string comment
    );

    // ERRORS
    error EmptyVoteComment();

    // FUNCTIONS
    /// @notice Cast a vote on a listing
    /// @param listingId The ID of the listing to vote on
    /// @param isAttestation True for attestation, false for refutation
    /// @param comment Required explanation for the vote
    /// @return commentId The ID of the created vote comment
    function castVote(
        uint256 listingId,
        bool isAttestation,
        string calldata comment
    ) external returns (uint256);

    /// @notice Check if an address has voted on a listing
    /// @param voter The address to check
    /// @param listingId The ID of the listing
    /// @return True if the address has voted
    function hasVoted(address voter, uint256 listingId) external view returns (bool);

    /// @notice Get the vote counts for a listing
    /// @param listingId The ID of the listing
    /// @return attestCount Number of attestations
    /// @return refuteCount Number of refutations
    function getVoteCount(uint256 listingId) 
        external 
        view 
        returns (uint256 attestCount, uint256 refuteCount);

    /// @notice Get list of addresses that voted on a listing
    /// @param listingId The ID of the listing
    /// @return Array of voter addresses
    function getVoterList(uint256 listingId) external view returns (address[] memory);

    /// @notice Get the vote type for a vote ID
    /// @param voteId The ID of the vote
    /// @return True if the vote is an attestation, false if it's a refutation
    function getVoteType(uint256 voteId) external view returns (bool);
}
