// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {AppStorage} from "./LibAppStorage.sol";

// this facet: create, edit, archive entries
// alot of this facets states would be shared

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
}
