// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
// import "@openzeppelin/contracts/utils/Counters.sol";
import "../libraries/LibAppStorage.sol";

contract NFTFacet is IERC721, IERC721Metadata {
    AppStorage internal s;

    event NFTMinted(
        address indexed to,
        uint256 indexed tokenId,
        uint256 indexed entryId,
        string uri
    );

    // ERC721Metadata
    function name() external pure override returns (string memory) {
        return "CAPOEP NFT";
    }

    function symbol() external pure override returns (string memory) {
        return "CAPOEP";
    }

    // Check if token exists
    function _exists(uint256 tokenId) internal view returns (bool) {
        return s.owners[tokenId] != address(0);
    }

    function tokenURI(
        uint256 tokenId
    ) external view override returns (string memory) {
        require(_exists(tokenId), "NFTFacet: URI query for nonexistent token");
        return s.tokenURIs[tokenId];
    }

    // ERC721
    function balanceOf(address owner) external view override returns (uint256) {
        require(
            owner != address(0),
            "NFTFacet: balance query for zero address"
        );
        return s.balances[owner];
    }

    function ownerOf(uint256 tokenId) external view override returns (address) {
        address owner = s.owners[tokenId];
        require(
            owner != address(0),
            "NFTFacet: owner query for nonexistent token"
        );
        return owner;
    }

    // Minting function
    function mintNFT(uint256 entryId, string memory uri) external {
        require(!s.paused, "NFTFacet: Contract is paused");
        require(
            s.entries[entryId].creator == msg.sender,
            "NFTFacet: Only entry creator can mint"
        );
        require(
            s.entries[entryId].totalAttestCount >= MIN_ATTESTATIONS_FOR_MINT,
            "NFTFacet: Not enough attestations"
        );
        require(!s.hasMinted[msg.sender], "NFTFacet: User has already minted");

        uint256 tokenId = s.nextTokenId;
        s.nextTokenId++;

        _mint(msg.sender, tokenId);
        s.tokenURIs[tokenId] = uri;
        s.tokenToEntryId[tokenId] = entryId;
        s.hasMinted[msg.sender] = true;

        emit NFTMinted(msg.sender, tokenId, entryId, uri);
    }

    // Internal minting function
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "NFTFacet: mint to zero address");
        require(!_exists(tokenId), "NFTFacet: token already minted");

        s.balances[to] += 1;
        s.owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    // // Check if token exists
    // function _exists(uint256 tokenId) internal view returns (bool) {
    //     return s.owners[tokenId] != address(0);
    // }

    // Soulbound tokens (non-transferable)
    function approve(address to, uint256 tokenId) external override {
        revert(
            "NFTFacet: CAPOEP tokens are soulbound and cannot be transferred"
        );
    }

    function getApproved(
        uint256 tokenId
    ) external view override returns (address) {
        require(
            _exists(tokenId),
            "NFTFacet: approved query for nonexistent token"
        );
        return address(0);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) external override {
        revert(
            "NFTFacet: CAPOEP tokens are soulbound and cannot be transferred"
        );
    }

    function isApprovedForAll(
        address owner,
        address operator
    ) external pure override returns (bool) {
        return false;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        revert(
            "NFTFacet: CAPOEP tokens are soulbound and cannot be transferred"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        revert(
            "NFTFacet: CAPOEP tokens are soulbound and cannot be transferred"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external override {
        revert(
            "NFTFacet: CAPOEP tokens are soulbound and cannot be transferred"
        );
    }

    // Pause/unpause functionality
    function pause() external {
        LibDiamond.enforceIsContractOwner();
        s.paused = true;
    }

    function unpause() external {
        LibDiamond.enforceIsContractOwner();
        s.paused = false;
    }
}
