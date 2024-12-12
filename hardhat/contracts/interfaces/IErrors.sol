// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IErrors {
    error ListingNotActive();
    error UnauthorizedAccess();
    error ListingAlreadyExists();
    error InsufficientReputation();
    // Add other common errors here
}
