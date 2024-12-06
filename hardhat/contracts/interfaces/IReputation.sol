// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @title IReputation Interface
/// @notice Interface for the reputation system of CAPOEP
/// @dev Implements point-based reputation tracking for user actions
interface IReputation {
    // EVENTS

    /// @notice Emitted when a user's reputation changes
    /// @param user Address of the user
    /// @param change Point change amount (positive or negative)
    /// @param reason Description of why the change occurred
    event ReputationChanged(address indexed user, int256 change, string reason);

    // CORE FUNCTIONS

    /// @notice Updates a user's reputation score
    /// @param user Address of the user
    /// @param points Points to add (positive) or subtract (negative)
    /// @param reason Description of the change
    function updateReputation(
        address user,
        int256 points,
        string memory reason
    ) external;

    // VIEW FUNCTIONS

    /// @notice Get the reputation score for an address
    /// @param user The address to check
    /// @return The user's current reputation score
    function getReputation(address user) external view returns (int256);

    /// @notice Check if a user meets minimum reputation threshold
    /// @param user The address to check
    /// @param threshold The minimum required reputation
    /// @return Whether the user meets the threshold
    function meetsReputationThreshold(
        address user,
        int256 threshold
    ) external view returns (bool);
}
