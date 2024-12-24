// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// learned from: https://github.com/aavegotchi/aavegotchi-contracts/blob/master/contracts/Aavegotchi/libraries/LibAppStorage.sol
// learned from: eip 2535 app storage reff implementation

uint256 constant EQUIPPED_WEARABLE_SLOTS = 16;
uint256 constant NUMERIC_TRAITS_NUM = 6;
uint256 constant TRAIT_BONUSES_NUM = 5;
uint256 constant PORTAL_AAVEGOTCHIS_NUM = 10;
// constants can be used in appstorage and structs outside app storage

// example of struct that would be used in a mapping etc within appstorage:
// (do not create structs directly in appstorage)
// struct Dimensions {
//     uint8 x;
//     uint8 y;
//     uint8 width;
//     uint8 height;
// }

struct AppStorage {
    uint256 secondVar;
    uint256 firstVar;
    uint256 lastVar;
    // add other state variables ...

    // EntryFacet
    
}

library LibAppStorage {
    function appStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

    function someFunction() internal {
        AppStorage storage s = appStorage();
        s.firstVar = 8;
        //... do more stuff
    }
}

contract Modifiers {
    // AppStorage internal s;
    // modifier onlyAavegotchiOwner(uint256 _tokenId) {
    //     require(LibMeta.msgSender() == s.aavegotchis[_tokenId].owner, "LibAppStorage: Only aavegotchi owner can call this function");
    //     _;
    // }
    // modifier onlyUnlocked(uint256 _tokenId) {
    //     require(s.aavegotchis[_tokenId].locked == false, "LibAppStorage: Only callable on unlocked Aavegotchis");
    //     _;
    // }
    // modifier onlyLocked(uint256 _tokenId) {
    //     require(s.aavegotchis[_tokenId].locked == true, "LibAppStorage: Only callable on locked Aavegotchis");
    //     _;
    // }
    // modifier onlyOwner() {
    //     LibDiamond.enforceIsContractOwner();
    //     _;
    // }
    // modifier onlyDao() {
    //     address sender = LibMeta.msgSender();
    //     require(sender == s.dao, "Only DAO can call this function");
    //     _;
    // }
    // modifier onlyDaoOrOwner() {
    //     address sender = LibMeta.msgSender();
    //     require(sender == s.dao || sender == LibDiamond.contractOwner(), "LibAppStorage: Do not have access");
    //     _;
    // }
    // modifier onlyOwnerOrDaoOrGameManager() {
    //     address sender = LibMeta.msgSender();
    //     bool isGameManager = s.gameManagers[sender].limit != 0;
    //     require(sender == s.dao || sender == LibDiamond.contractOwner() || isGameManager, "LibAppStorage: Do not have access");
    //     _;
    // }
    // modifier onlyItemManager() {
    //     address sender = LibMeta.msgSender();
    //     require(s.itemManagers[sender] == true, "LibAppStorage: only an ItemManager can call this function");
    //     _;
    // }
    // modifier onlyOwnerOrItemManager() {
    //     address sender = LibMeta.msgSender();
    //     require(
    //         sender == LibDiamond.contractOwner() || s.itemManagers[sender] == true,
    //         "LibAppStorage: only an Owner or ItemManager can call this function"
    //     );
    //     _;
    // }
}
