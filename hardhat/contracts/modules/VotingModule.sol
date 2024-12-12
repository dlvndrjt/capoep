// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../interfaces/IVoting.sol";
import "../interfaces/IListing.sol";
import "../interfaces/IComments.sol";
import "../interfaces/IReputation.sol";

contract VotingModule is IVoting {
    // STATE VARIABLES
    IListing private immutable _listingModule;
    IComments private immutable _commentsModule;
    IReputation private immutable _reputationModule;
    
    mapping(address => mapping(uint256 => bool)) private _hasVoted;
    mapping(uint256 => address[]) private _listingVoters;
    uint256 private _nextVoteId;
    
    // Add constants at the top
    int256 private constant MIN_REPUTATION_TO_VOTE = -10;
    
    // Add state variable to track vote types
    mapping(uint256 => bool) private _voteTypes; // true for attestation, false for refutation
    
    constructor(
        address listingModule,
        address commentsModule,
        address reputationModule
    ) {
        _listingModule = IListing(listingModule);
        _commentsModule = IComments(commentsModule);
        _reputationModule = IReputation(reputationModule);
    }
    
    function castVote(
        uint256 listingId,
        bool isAttestation,
        string calldata comment
    ) external returns (uint256) {
        if (bytes(comment).length == 0) revert EmptyVoteComment();
        if (!_listingModule.isListingActive(listingId)) revert ListingNotActive();
        if (_reputationModule.getReputation(msg.sender) <= MIN_REPUTATION_TO_VOTE) 
            revert InsufficientReputation();
        if (_hasVoted[msg.sender][listingId]) revert AlreadyVoted();
        
        IListing.Listing memory listing = _listingModule.getListing(listingId);
        if (listing.creator == msg.sender) revert CannotVoteOwnListing();
        
        // Record vote and add to voter list
        _hasVoted[msg.sender][listingId] = true;
        _listingVoters[listingId].push(msg.sender);
        
        // Update listing counts
        _listingModule.updateListingCounts(listingId, isAttestation);
        
        // Create vote comment and emit event
        uint256 commentId = _commentsModule.addVoteComment(
            listingId,
            _nextVoteId,
            comment,
            msg.sender
        );
        
        _voteTypes[_nextVoteId] = isAttestation;
        _nextVoteId++;
        
        // Update reputation
        _reputationModule.updateReputationFromVote(listing.creator, isAttestation);
        
        emit VoteCast(listingId, msg.sender, isAttestation, comment);
        return commentId;
    }

    function hasVoted(
        address voter,
        uint256 listingId
    ) external view returns (bool) {
        return _hasVoted[voter][listingId];
    }

    function getVoteCount(uint256 listingId) external view returns (uint256 attestCount, uint256 refuteCount) {
        return _listingModule.getListingCounts(listingId);
    }

    function getVoterList(uint256 listingId) external view returns (address[] memory) {
        return _listingVoters[listingId];
    }

    // Add these errors
    error ListingNotActive();
    error InsufficientReputation();
    error AlreadyVoted();
    error CannotVoteOwnListing();

    // Add the missing function
    function getVoteType(uint256 voteId) external view override returns (bool) {
        return _voteTypes[voteId];
    }
}
