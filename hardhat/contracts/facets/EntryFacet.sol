// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;
import {AppStorage} from "./LibAppStorage.sol";

contract EntryFacet {
    AppStorage internal s;

    // Function to create a new entry (linked to a previous entry if provided)
    function createEntry(
        string memory title,
        string memory details,
        string[] memory proofs,
        string memory category,
        uint256 previousEntryId, // ID of the previous entry in the chain (0 if none)
    ) external {
        if (previousEntryId != 0) {
            // Ensure the user is the creator of the previous entry
            require(s.Entries[previousEntryId].creator == msg.sender, "Only creator of archived entry can create a new linked entry to the archived entry");
            // Ensure the previous entry is archived
            require(s.Entries[previousEntryId].state == EntryState.Archived, "Previous entry must be archived");
        }

        // Check if entry already exists (based on a hash of the title, details, and category)
        bytes32 entryHash = keccak256(
            abi.encodePacked(title, details, category)
        ); // i think its better to include the creator address in the hash
        require(!s.EntryHashes[entryHash], "Entry already exists");

        // Create new entry ID and update AppStorage
        uint256 newEntryId = s.nextEntryId;
        s.nextEntryId++;

        // Create the new entry
        s.Entries[newEntryId] = Entry({
            id: newEntryId,
            creator: msg.sender,
            title: title,
            details: details,
            proofs: proofs,
            category: category,
            createdAt: block.timestamp,
            editedAt: block.timestamp,
            state: EntryState.Active,
            votes: new VoteDetail,
            totalAttestCount: 0,
            totalRefuteCount: 0,
            linkedToPreviousId: previousEntryId,
            linkedToNewId: 0,
            archiveNote: ""
        });

        // Mark the entry hash as used to prevent duplicates
        s.EntryHashes[entryHash] = true;

        // Add the entry to the user's list of created entries
        s.users[msg.sender].createdEntries.push(newEntryId);

        // Link the new entry to the previous one
        s.Entries[previousEntryId].linkedToNewId = newEntryId;
    }

    // Function to edit an entry
    function editEntry(uint256 entryId, string memory newtitle, string memory newDetails, string[] memory newProofs,) external {

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
       entry.title = bytes(newtitle).length != 0 ? newtitle : entry.title;
        entry.details = bytes(newDetails).length != 0 ? newDetails : entry.details;
        entry.proofs = newProofs.length != 0 ? newProofs : entry.proofs;

        entry.editedAt = block.timestamp;
    }
    
    // need 3 mechanisms for entry archival:
    // archive only 
    // create a new entry on-top of the archived entry 
    // archive and create a new entry on-top of the archived entry
    // (if minted then when entry is archived then the nft is burned as well)

    function archiveEntry(uint256 entryId, string archiveNote) external {
        Entry storage entry = s.Entries[entryId];
        require(entry.creator == msg.sender, "Only the creator can archive the entry");
        require(entry.state !== EntryState.Archived, "Entry is already archived");
        if (entry.state == EntryState.Minted) {
            // Burn the token if it was minted
            // burnToken(entryId);
        }
        entry.state = EntryState.Archived;
        entry.archiveNote = archiveNote;
        entry.archivedAt = block.timestamp;
    }

    // function to archive an entry and create a new entry on top of the archived entry in the same transaction
    function archiveAndCreateNewEntry(uint256 entryId, string memory archiveNote, string memory title, string memory details, string[] memory proofs, string memory category,) external {
        archiveEntry(entryId, archiveNote);
        createEntry(title, details, proofs, category, entryId);
    
    }
}
