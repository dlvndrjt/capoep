// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../interfaces/IReputation.sol";

/// @title ReputationModule
/// @notice Implements reputation tracking system for CAPOEP
/// @dev Manages user reputation scores and thresholds
contract ReputationModule is IReputation {
    // CUSTOM ERRORS

    error UnauthorizedUpdate();
    error InvalidReputationChange();

    // STATE VARIABLES

    /// @dev Maps addresses to their reputation scores
    mapping(address => int256) private _reputationScores;

    /// @dev Addresses authorized to update reputation
    mapping(address => bool) private _authorizedUpdaters;

    // MODIFIERS

    /// @notice Ensures caller is authorized to update reputation
    modifier onlyAuthorized() {
        if (!_authorizedUpdaters[msg.sender]) revert UnauthorizedUpdate();
        _;
    }

    // CORE FUNCTIONS

    /// @inheritdoc IReputation
    function updateReputation(
        address user,
        int256 points,
        string memory reason
    ) external override onlyAuthorized {
        if (points == 0) revert InvalidReputationChange();

        _reputationScores[user] += points;

        emit ReputationChanged(user, points, reason);
    }

    // VIEW FUNCTIONS

    /// @inheritdoc IReputation
    function getReputation(
        address user
    ) external view override returns (int256) {
        return _reputationScores[user];
    }

    /// @inheritdoc IReputation
    function meetsReputationThreshold(
        address user,
        int256 threshold
    ) external view override returns (bool) {
        return _reputationScores[user] >= threshold;
    }

    // ADMIN FUNCTIONS

    /// @notice Adds an authorized updater
    /// @param updater Address to authorize
    function addAuthorizedUpdater(address updater) external {
        _authorizedUpdaters[updater] = true;
    }

    /// @notice Removes an authorized updater
    /// @param updater Address to remove
    function removeAuthorizedUpdater(address updater) external {
        _authorizedUpdaters[updater] = false;
    }
}
