
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {AppStorage} from "./LibAppStorage.sol";
import "./LibAppStorage.sol";

// Example:
// contract AFacet {
//     AppStorage internal s;

//     function sumVariables() external {
//         s.lastVar = s.firstVar + s.secondVar;
//     }

//     function getFirsVar() external view returns (uint256) {
//         return s.firstVar;
//     }

//     function setLastVar(uint256 _newValue) external {
//         s.lastVar = _newValue;
//     }
// }

contract EntryFacet {
    AppStorage internal s;

    // Function to create a new entry
    function createEntry(
        string calldata title, 
        string calldata details, 
        string[] calldata proofs, 
        string calldata category
    ) external returns (uint256) {
        // Generate a new unique Entry ID
        uint256 entryId = s.nextEntryId;
        s.nextEntryId++; // Increment to ensure unique ID

        // Create the new Entry struct
        Entry memory newEntry = Entry({
            id: entryId,
            creator: msg.sender,
            title: title,
            details: details,
            proofs: proofs,
            category: category,
            createdAt: block.timestamp,
            state: EntryState.Active,
            votes: new VoteDetail Empty votes initially
            totalAttestCount: 0,
            totalRefuteCount: 0,
            linkedToPreviousId: 0, // No previous entry
            linkedToNewId: 0, // No linked new entry
            archiveNote: ""  // No archive note initially
        });

        // Store the new Entry in AppStorage
        s.Entries[entryId] = newEntry;

        // Add the entry to the creator's list of created entries
        s.users[msg.sender].createdEntries.push(entryId);

        // Return the new entry ID
        return entryId;
    }

}