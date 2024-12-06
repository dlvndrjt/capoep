// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../interfaces/IVoting.sol";

/// @title VotingModule
/// @notice Implements voting functionality for CAPOEP
/// @dev Handles attestations, refutations, and vote feedback
contract VotingModule is IVoting {
    // CUSTOM ERRORS

    error AlreadyVoted();
    error VoteDoesNotExist();
    error ListingNotActive();
    error EmptyComment();

    // STATE VARIABLES

    /// @dev Maps listing IDs to voter addresses to their votes
    mapping(uint256 => mapping(address => Vote)) private _votes;

    /// @dev Maps listing IDs to arrays of voter addresses
    mapping(uint256 => address[]) private _listingVoters;

    // CORE FUNCTIONS

    /// @inheritdoc IVoting
    function castVote(
        uint256 listingId,
        bool isAttest,
        string memory comment
    ) external override {
        if (_votes[listingId][msg.sender].timestamp != 0) revert AlreadyVoted();
        if (bytes(comment).length == 0) revert EmptyComment();

        _votes[listingId][msg.sender] = Vote({
            isAttest: isAttest,
            comment: comment,
            timestamp: block.timestamp,
            upvotes: 0,
            downvotes: 0
        });

        _listingVoters[listingId].push(msg.sender);

        emit VoteCast(listingId, msg.sender, isAttest, comment);
    }

    /// @inheritdoc IVoting
    function giveVoteFeedback(
        uint256 listingId,
        address voter,
        bool isUpvote
    ) external override {
        Vote storage vote = _votes[listingId][voter];
        if (vote.timestamp == 0) revert VoteDoesNotExist();

        if (isUpvote) {
            vote.upvotes++;
        } else {
            vote.downvotes++;
        }

        emit VoteFeedback(listingId, voter, msg.sender, isUpvote);
    }

    // VIEW FUNCTIONS

    /// @inheritdoc IVoting
    function getVote(
        uint256 listingId,
        address voter
    ) external view override returns (Vote memory) {
        return _votes[listingId][voter];
    }

    /// @inheritdoc IVoting
    function getVoters(
        uint256 listingId
    ) external view override returns (address[] memory) {
        return _listingVoters[listingId];
    }
}
