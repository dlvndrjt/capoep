// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibAppStorage.sol";

contract EntryFacet {
    AppStorage internal s;

    // Event declarations
    event EntryCreated(
        uint256 indexed entryId,
        address indexed creator,
        string title,
        string category
    );
    event EntryEdited(
        uint256 indexed entryId,
        address indexed editor,
        string newTitle,
        string newDetails,
        string[] newProofs
    );
    event EntryArchived(
        uint256 indexed entryId,
        address indexed creator,
        string archiveNote
    );
    event EntryArchivedAndCreatedNew(
        uint256 indexed archivedEntryId,
        uint256 indexed newEntryId,
        address indexed creator,
        string archiveNote,
        string newTitle,
        string newCategory
    );
    event EntryVoted(
        uint256 indexed entryId,
        address indexed voter,
        string voteType,
        uint256 voteCommentId
    );
    event EntryUnvoted(uint256 indexed entryId, address indexed voter);

    // Function to create a new entry (linked to a previous entry if provided)
    function createEntry(
        string memory title,
        string memory details,
        string[] memory proofs,
        string memory category,
        uint256 previousEntryId // ID of the previous entry in the chain (0 if none)
    ) external {
        if (previousEntryId != 0) {
            // Ensure the user is the creator of the previous entry
            require(
                s.Entries[previousEntryId].creator == msg.sender,
                "Only creator of archived entry can create a new linked entry to the archived entry"
            );
            // Ensure the previous entry is archived
            require(
                s.Entries[previousEntryId].state == EntryState.Archived,
                "Previous entry must be archived"
            );
        }

        // Check if entry already exists by the same user to prevent duplicate entries by the same user (based on a hash of the address, title, details, and category)
        bytes32 entryHash = keccak256(
            abi.encodePacked(msg.sender, title, details, category)
        );
        require(!s.EntryHashes[entryHash], "Entry already exists");

        // Create new entry ID and update AppStorage
        uint256 newEntryId = s.nextEntryId;
        s.nextEntryId++;

        // Create the new entry
        // (the following is giving an error: "Types in storage containing (nested) mappings cannot be assigned to.solidity(9214) uint256 newEntryId") Thus I have to use the following code after the commented code
        // s.Entries[newEntryId] = Entry({
        //     id: newEntryId,
        //     creator: msg.sender,
        //     title: title,
        //     details: details,
        //     proofs: proofs,
        //     category: category,
        //     createdAt: block.timestamp,
        //     editedAt: block.timestamp,
        //     state: EntryState.Active,
        //     votes: new VoteDetail,
        //     totalAttestCount: 0,
        //     totalRefuteCount: 0,
        //     linkedToPreviousId: previousEntryId,
        //     linkedToNewId: 0,
        //     previousEntries: new uint256, // Initialize as an empty array if no previous entries
        //     archiveNote: ""
        // });
        Entry storage newEntry = s.Entries[newEntryId];
        newEntry.id = newEntryId;
        newEntry.creator = msg.sender;
        newEntry.title = title;
        newEntry.details = details;
        newEntry.proofs = proofs;
        newEntry.category = category;
        newEntry.createdAt = block.timestamp;
        newEntry.editedAt = block.timestamp;
        newEntry.state = EntryState.Active;
        newEntry.votes = new VoteDetail[](0); // Initialize as an empty array if no votes
        newEntry.totalAttestCount = 0;
        newEntry.totalRefuteCount = 0;
        newEntry.linkedToPreviousId = previousEntryId;
        newEntry.linkedToNewId = 0;
        newEntry.previousEntries = new uint256[](0); // Initialize as an empty array if no previous entries
        newEntry.archiveNote = "";

        // Link to the previous entry if applicable
        if (previousEntryId != 0) {
            // Add the previous entry ID to the new entry's `previousEntries` array
            s.Entries[newEntryId].previousEntries.push(previousEntryId);
        }

        // Mark the entry hash as used to prevent duplicates
        s.EntryHashes[entryHash] = true;

        // Add the entry to the user's list of created entries
        s.users[msg.sender].createdEntries.push(newEntryId);

        // Link the new entry to the previous one
        s.Entries[previousEntryId].linkedToNewId = newEntryId;

        emit EntryCreated(newEntryId, msg.sender, title, category);
    }

    // Function to edit an entry
    function editEntry(
        uint256 entryId,
        string memory newTitle,
        string memory newDetails,
        string[] memory newProofs
    ) external {
        Entry storage entry = s.Entries[entryId];

        // Ensure the user is the creator and the entry is still in an editable state
        require(entry.creator == msg.sender, "Only creator can edit");
        require(
            entry.state == EntryState.Active,
            "Cannot edit archived or minted entry"
        );

        // Ensure there are no votes on the entry before editing
        require(
            entry.totalAttestCount == 0 && entry.totalRefuteCount == 0,
            "Cannot edit entry with votes"
        );

        // Update entry title, details, proofs, and timestamp
        if (bytes(newTitle).length != 0) {
            entry.title = newTitle;
        }
        if (bytes(newDetails).length != 0) {
            entry.details = newDetails;
        }
        if (newProofs.length != 0) {
            entry.proofs = newProofs;
        }

        // Update the edited timestamp if any of the fields were changed
        if (
            bytes(newTitle).length != 0 ||
            bytes(newDetails).length != 0 ||
            newProofs.length != 0
        ) {
            entry.editedAt = block.timestamp;
        }

        emit EntryEdited(entryId, msg.sender, newTitle, newDetails, newProofs);
    }

    function archiveEntry(uint256 entryId, string memory archiveNote) external {
        Entry storage entry = s.Entries[entryId];
        require(
            entry.creator == msg.sender,
            "Only the creator can archive the entry"
        );
        require(
            entry.state != EntryState.Archived,
            "Entry is already archived"
        );
        if (entry.state == EntryState.Minted) {
            // Burn the token if it was minted
            // burnToken(entryId);
        }
        entry.state = EntryState.Archived;
        entry.archiveNote = archiveNote;
        entry.archivedAt = block.timestamp;

        emit EntryArchived(entryId, msg.sender, archiveNote);
    }

    // function to archive an entry and create a new entry on top of the archived entry in the same transaction
    function archiveAndCreateNewEntry(
        uint256 entryId,
        string memory archiveNote,
        string memory title,
        string memory details,
        string[] memory proofs,
        string memory category
    ) external {
        // Call archiveEntry to archive the existing entry
        this.archiveEntry(entryId, archiveNote);
        // Call createEntry to create a new entry linked to the archived entry
        this.createEntry(title, details, proofs, category, entryId);
        emit EntryArchivedAndCreatedNew(
            entryId,
            s.nextEntryId - 1,
            msg.sender,
            archiveNote,
            title,
            category
        );
    }

    // Function to vote on an entry
    function voteOnEntry(
        uint256 entryId,
        bool isAttest,
        uint256 voteCommentId
    ) external {
        Entry storage entry = s.Entries[entryId];

        // Check if the entry is archived
        require(
            entry.state != EntryState.Archived,
            "Cannot vote on archived entry"
        );

        // Check if user is the entry creator
        require(entry.creator != msg.sender, "Cannot vote on own entry");

        // Check if the user has already voted
        require(
            !s.users[msg.sender].hasVotedEntry[entryId],
            "User has already voted on this entry"
        );

        // Record the vote
        VoteDetail memory newVote = VoteDetail({
            voter: msg.sender,
            voteType: isAttest ? VoteType.Attest : VoteType.Refute,
            voteCommentId: voteCommentId,
            voteIndex: entry.votes.length,
            votedAt: block.timestamp
        });

        // Map the user's address to their vote
        entry.addressToVotes[msg.sender] = newVote;

        // Add vote to the entry's votes array
        entry.votes.push(newVote);

        // Update total vote counts
        if (isAttest) {
            entry.totalAttestCount++;
        } else if (!isAttest) {
            entry.totalRefuteCount++;
        }

        // Mark the user as having voted
        s.users[msg.sender].hasVotedEntry[entryId] = true;

        // Add the entry to the user's list of voted entries
        s.users[msg.sender].votedEntries.push(entryId);

        // Record the vote in the user's entryVotes mapping
        s.users[msg.sender].entryVotes[entryId] = newVote;

        emit EntryVoted(
            entryId,
            msg.sender,
            isAttest ? "Attest" : "Refute",
            voteCommentId
        );
    }

    // Function to unvote on an entry
    function unvoteEntry(uint256 entryId) external {
        Entry storage entry = s.Entries[entryId];

        require(
            s.users[msg.sender].hasVotedEntry[entryId],
            "User has not voted on this entry"
        );

        // Get the user's vote details
        VoteDetail memory userVote = entry.addressToVotes[msg.sender];

        // Remove the vote from the entry's votes array
        // delete entry.votes[userVote.voteIndex];
        entry.votes[userVote.voteIndex] = entry.votes[entry.votes.length - 1];
        entry.votes.pop();

        // Remove the vote from the addressToVotes mapping
        delete entry.addressToVotes[msg.sender];

        // Remove the vote from the user's entryVotes mapping
        delete s.users[msg.sender].entryVotes[entryId];

        // Mark the user as not having voted on this entry
        s.users[msg.sender].hasVotedEntry[entryId] = false;

        // Update total vote counts
        if (userVote.voteType == VoteType.Attest) {
            entry.totalAttestCount--;
        } else if (userVote.voteType == VoteType.Refute) {
            entry.totalRefuteCount--;
        }

        emit EntryUnvoted(entryId, msg.sender);
    }
}
