// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../interfaces/IReputation.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

/// @title ReputationModule
/// @notice Implements reputation tracking system for CAPOEP
/// @dev Manages user reputation scores and thresholds
contract ReputationModule is IReputation, Ownable {
    // CUSTOM ERRORS
    error UnauthorizedUpdate();
    error InvalidReputationChange();
    error InvalidAddress();

    // CONSTANTS
    /// @dev Points awarded/deducted for different actions
    int256 public constant ATTEST_POINTS = 1;
    int256 public constant REFUTE_POINTS = -1;
    int256 public constant UPVOTE_POINTS = 1;
    int256 public constant DOWNVOTE_POINTS = -1;
    int256 public constant COMMENT_UPVOTE_POINTS = 1;
    int256 public constant COMMENT_DOWNVOTE_POINTS = -1;

    // STATE VARIABLES
    /// @dev Maps addresses to their reputation scores
    mapping(address => int256) private _reputationScores;

    /// @dev Addresses authorized to update reputation (voting module, comments module)
    mapping(address => bool) private _authorizedUpdaters;

    // EVENTS
    /// @notice Emitted when an updater is authorized or unauthorized
    event UpdaterStatusChanged(address indexed updater, bool isAuthorized);

    // MODIFIERS
    /// @notice Ensures caller is authorized to update reputation
    modifier onlyAuthorized() {
        if (!_authorizedUpdaters[msg.sender]) revert UnauthorizedUpdate();
        _;
        // require(_authorizedUpdaters[msg.sender], "UnauthorizedUpdate()");
        _;
    }

    /// @notice Ensures address is valid
    modifier validAddress(address user) {
        if (user == address(0)) revert InvalidAddress();
        _;
    }

    // CONSTRUCTOR
    constructor(address initialOwner) Ownable(initialOwner) {
        console.log("ReputationModule initialized with owner:", initialOwner);
    }

    // CORE FUNCTIONS

    /// @inheritdoc IReputation
    function updateReputation(
        address user,
        int256 points,
        string memory reason
    ) external onlyAuthorized validAddress(user) {
        int256 oldScore = _reputationScores[user];
        _reputationScores[user] += points;
        emit ReputationChanged(user, oldScore, _reputationScores[user], reason);
    }

    /// @notice Updates reputation based on voting
    /// @param user Address receiving the reputation change
    /// @param isAttest Whether the vote was an attestation
    function updateReputationFromVote(
        address user,
        bool isAttest
    ) external onlyAuthorized validAddress(user) {
        int256 points = isAttest ? ATTEST_POINTS : REFUTE_POINTS;
        int256 oldScore = _reputationScores[user];
        _reputationScores[user] += points;
        emit ReputationChanged(
            user,
            oldScore,
            _reputationScores[user],
            isAttest ? "Received attestation" : "Received refutation"
        );
    }

    /// @notice Updates reputation based on vote/comment feedback
    /// @param user Address receiving the reputation change
    /// @param isUpvote Whether the feedback was positive
    function updateReputationFromFeedback(
        address user,
        bool isUpvote
    ) external onlyAuthorized validAddress(user) {
        int256 points = isUpvote ? UPVOTE_POINTS : DOWNVOTE_POINTS;
        int256 oldScore = _reputationScores[user];
        _reputationScores[user] += points;

        emit ReputationChanged(
            user,
            oldScore,
            _reputationScores[user],
            isUpvote ? "Received upvote" : "Received downvote"
        );
    }

    /// @notice Updates reputation based on comment feedback
    /// @param user Address receiving the reputation change
    /// @param isUpvote Whether the feedback was positive
    function updateReputationFromCommentFeedback(
        address user,
        bool isUpvote
    ) external onlyAuthorized validAddress(user) {
        int256 points = isUpvote
            ? COMMENT_UPVOTE_POINTS
            : COMMENT_DOWNVOTE_POINTS;
        int256 oldScore = _reputationScores[user];
        _reputationScores[user] += points;

        emit ReputationChanged(
            user,
            oldScore,
            _reputationScores[user],
            isUpvote ? "Comment upvoted" : "Comment downvoted"
        );
    }

    /// @notice Updates reputation based on comment feedback
    /// @param user Address receiving the reputation change
    /// @param isUpvote Whether the feedback was positive
    function updateReputationFromComment(
        address user,
        bool isUpvote
    ) external override onlyAuthorized {
        int256 points = isUpvote ? COMMENT_UPVOTE_POINTS : COMMENT_DOWNVOTE_POINTS;
        _reputationScores[user] += points;
        emit ReputationChanged(
            user,
            _reputationScores[user] - points,
            _reputationScores[user],
            isUpvote ? "Comment upvoted" : "Comment downvoted"
        );
    }

    /// @notice Updates reputation based on vote/comment feedback
    /// @param user Address receiving the reputation change
    /// @param isUpvote Whether the feedback was positive
    function updateReputationFromVoteComment(
        address user,
        bool isUpvote
    ) external override onlyAuthorized {
        int256 points = isUpvote ? COMMENT_UPVOTE_POINTS : COMMENT_DOWNVOTE_POINTS;
        _reputationScores[user] += points;
        emit ReputationChanged(
            user,
            _reputationScores[user] - points,
            _reputationScores[user],
            isUpvote ? "Vote comment upvoted" : "Vote comment downvoted"
        );
    }

    // VIEW FUNCTIONS

    /// @inheritdoc IReputation
    function getReputation(address user) external view returns (int256) {
        return _reputationScores[user];
    }

    /// @inheritdoc IReputation
    function meetsReputationThreshold(
        address user,
        int256 threshold
    ) external view returns (bool) {
        return _reputationScores[user] >= threshold;
    }

    /// @notice Checks if an address is authorized to update reputation
    /// @param updater Address to check
    /// @return bool indicating if address is authorized
    function isAuthorizedUpdater(address updater) external view returns (bool) {
        return _authorizedUpdaters[updater];
    }

    // ADMIN FUNCTIONS

    /// @notice Adds an address as an authorized updater
    /// @param updater Address to authorize for reputation updates
    function addAuthorizedUpdater(address updater) external onlyOwner {
        console.log("Adding authorized updater:", updater); // Log the updater's address
        _authorizedUpdaters[updater] = true;
        console.log("Is updater authorized:", _authorizedUpdaters[updater]);
        emit UpdaterStatusChanged(updater, true);
    }

    /// @notice Removes an address from authorized updaters
    /// @param updater Address to remove from authorized updaters
    function removeAuthorizedUpdater(address updater) external onlyOwner {
        _authorizedUpdaters[updater] = false;
        emit UpdaterStatusChanged(updater, false);
    }

    /// @notice Initializes authorized updaters
    /// @param updaters An array of addresses to be authorized
    function initializeAuthorizedUpdaters(
        address[] memory updaters
    ) external onlyOwner {
        require(msg.sender == owner(), "Caller is not the owner");
        emit UpdaterStatusChanged(msg.sender, true); // Log the caller
        emit UpdaterStatusChanged(owner(), true); // Log the owner address
        require(msg.sender == owner(), "Owner address mismatch"); // Confirm owner address
        for (uint256 i = 0; i < updaters.length; i++) {
            _authorizedUpdaters[updaters[i]] = true;
            emit UpdaterStatusChanged(updaters[i], true);
        }
    }

    /// @notice Sets initial reputation for a user
    /// @param user Address to set initial reputation for
    /// @param initialReputation Initial reputation score to set
    function setInitialReputation(
        address user,
        int256 initialReputation
    ) external onlyOwner validAddress(user) {
        // Ensure initial reputation is not set already
        require(_reputationScores[user] == 0, "Reputation already set");

        int256 oldScore = _reputationScores[user];
        _reputationScores[user] = initialReputation;

        emit ReputationChanged(
            user,
            oldScore,
            initialReputation,
            "Initial reputation set"
        );
    }
}
