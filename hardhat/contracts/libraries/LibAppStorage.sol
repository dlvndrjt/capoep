// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// learned from: https://github.com/aavegotchi/aavegotchi-contracts/blob/master/contracts/Aavegotchi/libraries/LibAppStorage.sol
// learned from: eip 2535 app storage reff implementation

// CONSTANTS
uint256 constant MIN_ATTESTATIONS_FOR_MINT = 2;
// constants can be used in appstorage and structs outside app storage

// (do not create structs directly in appstorage)

// USER STATES
// The User struct which stores the details of each user
struct User {
    uint256 id; // The ID of the User
    string name; // Name of the user
    address walletAddress; // Wallet address of the user
    uint256 registeredAt; // Timestamp of user registration
    uint256 reputationScore; // Reputation score of the user
    uint256[] createdEntries; // List of Entry IDs created by the user
    uint256[] votedEntries; // List of Entry IDs the user has voted on. (contains voteDetails(vote+comment))
    uint256[] commentedEntries; // List of Entry IDs the user has commented on
    uint256[] votedOnCommentsEntries; // List of Entry IDs where the user has voted on comments
    mapping(uint256 => bool) hasVotedEntry; // Mapping to track whether the user has voted on a specific Entry
}
// USER STATES END

// ENTRY STATES
// Enum for Entry states
enum EntryState {
    Active,
    Archived,
    Minted
}

// Enum for Vote Types
enum VoteType {
    Attest,
    Refute
}

// Struct to store vote details along with the comment
struct VoteDetail {
    VoteType voteType; // Type of the vote (Attest or Refute)
    uint256 voteCommentId; // ID linking to a VoteComment for this vote
    uint256 votedAt; // Timestamp of vote
}

// The Entry struct which stores the details of each Entry
struct Entry {
    uint256 id; // The ID of the Entry
    address creator; // The creator of the Entry
    string title; // Title of the Entry
    string details; // Details of the Entry
    string[] proofs; // Proofs related to the Entry
    string category; // Category of the Entry
    uint256 createdAt; // Timestamp of Entry creation
    EntryState state; // Current state of the Entry (Active, Archived, Minted)
    VoteDetail[] votes; // Array of vote details (attest/refute + comment) for the Entry
    uint256 totalAttestCount; // Total number of attest votes for the Entry
    uint256 totalRefuteCount; // Total number of refute votes for the Entry
    uint256 linkedToPreviousId; // Linked to a previous Entry if current Entry is made on top of an archived Entry
    uint256 linkedToNewId; // Linked to a new Entry if current Entry is archived and a new Entry is made on top of it
    string archiveNote; // Archive note when applicable
}
// ENTRY STATES END

// COMMENT STATES

// A struct to store vote details for each comment
struct CommentVote {
    address voter; // The address of the voter
    bool isUpvote; // True if upvote, false if downvote
    uint256 timestamp; // Timestamp when the vote was cast
}

// Unified Comment struct for both Vote-Comments and General Comments
struct Comment {
    uint256 id; // Unique ID of the comment
    bool isVoteComment; // Flag to indicate if it's a vote-comment or a general comment
    address author; // Author of the comment
    string content; // Content of the comment
    uint256 timestamp; // Timestamp when the comment was created
    uint256 parentId; // Parent comment ID (0 if it's a root comment)
    uint256 entryId; // The associated Entry ID (for general comments)
    uint256 voteId; // The associated Vote ID (for vote-comments)
    uint256[] replies; // List of Comment IDs for replies (nested comments)
    // Mappings for upvotes and downvotes
    mapping(address => CommentVote) upvotes; // Mapping to store upvotes (address => vote details)
    mapping(address => CommentVote) downvotes; // Mapping to store downvotes (address => vote details)
}

// COMMENT STATES END

// The storage struct holds all necessary state variables for facets
struct AppStorage {
    // USER STORAGE
    uint256 nextUserId; // Counter for generating unique User IDs
    mapping(address => User) users; // User Address => User struct
    // USER STORAGE END

    // ENTRY STORAGE
    uint256 nextEntryId; // Counter for generating unique Entry IDs
    mapping(uint256 => Entry) Entries; // Stores Entries by ID
    mapping(bytes32 => bool) EntryHashes; // Prevents duplicate Entries
    mapping(uint256 => uint256[]) versionHistory; // Stores version history for each Entry
    // ENTRY STORAGE END

    // COMMENT STORAGE
    uint256 nextCommentId; // Counter for generating unique Comment IDs
    mapping(uint256 => Comment) comments; // Comment ID => Comment data
    mapping(uint256 => uint256[]) commentsByEntry; // Entry ID => List of Comment IDs (general comments)
    mapping(uint256 => uint256[]) commentsByVote; // Vote ID => List of Comment IDs (vote-comments)
    mapping(uint256 => uint256[]) repliesByComment; // Comment ID => List of Comment IDs (replies to comments)
    // COMMENT STORAGE END
}

library LibAppStorage {
    function appStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

    function someFunction() internal {
        AppStorage storage s = appStorage();
        // s.firstVar = 8;
        //... do more stuff
    }
}

// --- Modifiers ---

contract Modifiers {
    AppStorage internal s;

    modifier entryExists(uint256 entryId) {
        require(entryId < s.nextEntryId, "Invalid entry ID");
        _;
    }

    modifier onlyCreator(uint256 entryId) {
        require(
            msg.sender == s.Entries[entryId].creator,
            "Unauthorized: Not entry creator"
        );
        _;
    }

    modifier onlyActive(uint256 entryId) {
        require(
            s.Entries[entryId].state == EntryState.Active,
            "Invalid entry State: Not Active"
        );
        _;
    }

    //     modifier canEditentry(uint256 entryId) {
    //         require(
    //             entryId < s.nextEntryId &&
    //                 s.Entries[entryId].state == EntryState.Active &&
    //                 !hasVotes(entryId),
    //             "Cannot edit entry: Invalid state or has votes"
    //         );
    //         _;
    //     }

    //     function hasVotes(uint256 entryId) internal view returns (bool) {
    //         EntryCount memory counts = s.EntryCounts[entryId];
    //         return counts.attestCount > 0 || counts.refuteCount > 0;
    //     }
}
