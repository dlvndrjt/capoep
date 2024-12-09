// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../interfaces/IVoting.sol";
import "../interfaces/IListing.sol";
import "../interfaces/IReputation.sol";
import "../interfaces/IErrors.sol";
import "../libraries/ListingTypes.sol";

/// @title VotingModule
/// @notice Implements voting functionality for CAPOEP
/// @dev Handles attestations, refutations, and vote feedback
contract VotingModule is IVoting, IErrors {
    // CUSTOM ERRORS
    error AlreadyVoted();
    error VoteDoesNotExist();
    error EmptyVoteComment();
    error CannotVoteOwnListing();
    error InsufficientReputation(string reason);
    error CannotVoteMintedListing();

    // CONSTANTS
    /// @dev Minimum reputation required to vote
    int256 public constant MIN_REPUTATION_TO_VOTE = -10;

    /// @dev Reputation change for an attest vote
    int256 public constant ATTEST_VOTE_REPUTATION = 5;
    
    /// @dev Reputation change for a contest vote
    int256 public constant CONTEST_VOTE_REPUTATION = -5;

    // STATE VARIABLES
    /// @dev Reference to the reputation module
    IReputation private _reputationModule;

    /// @dev Maps listing IDs to voter addresses to their votes
    mapping(uint256 => mapping(address => IVoting.Vote)) private _votes;

    /// @dev Maps listing IDs to vote counts
    mapping(uint256 => IVoting.VoteCount) private _voteCounts;

    /// @dev Maps listing IDs to arrays of voter addresses
    mapping(uint256 => address[]) private _listingVoters;

    // EVENTS
    /// @notice Emitted when vote counts are updated
    event VoteCountsUpdated(
        uint256 indexed listingId,
        uint256 attestCount,
        uint256 contestCount
    );

    /// @notice Emitted when a voting error occurs
    event VotingError(
        address indexed voter, 
        int256 reputation, 
        string reason
    );

    // CONSTRUCTOR
    /// @notice Constructor to initialize the VotingModule
    /// @param reputationModule The address of the ReputationModule
    constructor(address reputationModule) {
        // Validate and store the reputation module address
        require(reputationModule != address(0), "Invalid reputation module");
        _reputationModule = IReputation(reputationModule);
    }

    // MODIFIERS
    /// @dev Ensures voter has sufficient reputation
    modifier sufficientReputation() {
        int256 voterReputation = _reputationModule.getReputation(msg.sender);
        if (voterReputation <= MIN_REPUTATION_TO_VOTE)
            revert InsufficientReputation("Insufficient reputation to vote");
        _;
    }

    // CORE FUNCTIONS

    /// @dev Helper function to convert uint256 to string
    function _uintToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        
        return string(buffer);
    }

    /// @inheritdoc IVoting
    function castVote(
        uint256 listingId, 
        bool isAttest, 
        string memory comment
    ) external override {
        // Validate vote parameters
        require(bytes(comment).length > 0, "Comment cannot be empty");

        // Check reputation threshold
        int256 voterReputation = _reputationModule.getReputation(msg.sender);
        require(voterReputation >= MIN_REPUTATION_TO_VOTE, "Insufficient reputation to vote");

        // Check if vote already exists
        if (_votes[listingId][msg.sender].timestamp != 0) {
            revert AlreadyVoted();
        }

        // Record vote
        _votes[listingId][msg.sender] = IVoting.Vote({
            isAttest: isAttest,
            comment: comment,
            timestamp: block.timestamp,
            upvotes: 0,
            downvotes: 0
        });

        // Add voter to list
        _listingVoters[listingId].push(msg.sender);

        // Update vote counts
        IVoting.VoteCount storage voteCount = _voteCounts[listingId];
        if (isAttest) {
            voteCount.attestCount++;
        } else {
            voteCount.contestCount++;
        }

        // Update voter's reputation based on vote
        try _reputationModule.updateReputation(
            msg.sender, 
            isAttest ? ATTEST_VOTE_REPUTATION : CONTEST_VOTE_REPUTATION, 
            string(abi.encodePacked("Vote on listing ", _uintToString(listingId)))
        ) {} catch Error(string memory reason) {
            emit VotingError(msg.sender, voterReputation, reason);
        }
    }

    /// @inheritdoc IVoting
    function giveVoteFeedback(
        uint256 listingId,
        address voter,
        bool isUpvote
    ) external override {
        IVoting.Vote storage vote = _votes[listingId][voter];
        if (vote.timestamp == 0) revert VoteDoesNotExist();

        // Prevent self-voting
        if (voter == msg.sender) revert UnauthorizedAccess();

        // Update vote feedback counts
        if (isUpvote) {
            vote.upvotes++;
        } else {
            vote.downvotes++;
        }

        // Update reputation for vote owner
        _reputationModule.updateReputationFromFeedback(voter, isUpvote);

        emit VoteFeedback(listingId, voter, msg.sender, isUpvote);
    }

    // VIEW FUNCTIONS

    /// @inheritdoc IVoting
    function getVote(
        uint256 listingId, 
        address voter
    ) external view override returns (IVoting.Vote memory) {
        return _votes[listingId][voter];
    }

    /// @inheritdoc IVoting
    function getVoteCount(
        uint256 listingId
    ) external view override returns (IVoting.VoteCount memory) {
        return _voteCounts[listingId];
    }

    /// @inheritdoc IVoting
    function getVoters(
        uint256 listingId
    ) external view override returns (address[] memory) {
        return _listingVoters[listingId];
    }
}
