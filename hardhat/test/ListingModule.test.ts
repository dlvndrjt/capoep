import { expect } from "chai";
import { ethers } from "hardhat";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { ListingModule } from "../typechain-types/contracts/modules/ListingModule";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("ListingModule", function () {
  let listingModule: ListingModule;
  let owner: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;

  // Enum values from contract
  enum ListingState {
    Active = 0,
    Archived = 1,
    Minted = 2
  }

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();
    const ListingModule = await ethers.getContractFactory("ListingModule");
    listingModule = await ListingModule.deploy();
    await listingModule.waitForDeployment();
  });

  describe("Listing Creation", function () {
    it("Should create a listing correctly", async function () {
      await listingModule.connect(user1).createListing(
        "Test Title",
        "Test Description",
        ["https://proof.com"],
        "Category"
      );
      const listing = await listingModule.getListing(0n);
      expect(listing.state).to.be.eq(BigInt(ListingState.Active));
      expect(listing.creator).to.be.eq(user1.address);
    });

    it("Should reject empty inputs", async function () {
      await expect(
        listingModule.connect(user1).createListing("", "Details", ["https://test.com"], "Category")
      ).to.be.revertedWithCustomError(listingModule, "EmptyTitle");
    });
  });

  describe("Listing Archival", function () {
    let firstListingId: bigint;
    let secondListingId: bigint;

    beforeEach(async function () {
      await listingModule.connect(user1).createListing(
        "Original Listing",
        "First listing",
        ["https://proof1.com"],
        "Category"
      );
      firstListingId = 0n;

      await listingModule.connect(user1).createListing(
        "New Listing",
        "Updated listing",
        ["https://proof2.com"],
        "Category"
      );
      secondListingId = 1n;
    });

    it("Should archive a listing correctly", async function () {
      await listingModule.connect(user1).archiveListing(firstListingId, secondListingId, "Archived with new version");
      const archivedListing = await listingModule.getListing(firstListingId);
      expect(archivedListing.state).to.be.eq(BigInt(ListingState.Archived));
      expect(archivedListing.linkedToId).to.be.eq(secondListingId);
    });

    it("Should prevent non-creator from archiving", async function () {
      // Create a listing
      await listingModule.connect(user1).createListing("Test Listing", "Details", ["https://test.com"], "Category");
      
      // Try to archive by another user
      await expect(
        listingModule.connect(user2).archiveListing(0, 1, "Archiving")
      ).to.be.revertedWithCustomError(listingModule, "UnauthorizedAccess");
    });

    it("Should prevent archiving an already archived listing", async function () {
      // Create a listing
      await listingModule.connect(user1).createListing("Test Listing", "Details", ["https://test.com"], "Category");
      
      // First archive
      await listingModule.connect(user1).archiveListing(0, 1, "First archive");
      
      // Try to archive again
      await expect(
        listingModule.connect(user1).archiveListing(0, 2, "Second archive")
      ).to.be.revertedWithCustomError(listingModule, "InvalidListingState");
    });
  });

  describe("Listing Validation", function () {
    it("Should prevent creating duplicate listings", async function () {
      // Create first listing
      await listingModule.connect(user1).createListing("Test Listing", "Details", ["https://test.com"], "Category");
      
      // Try to create with same details
      await expect(
        listingModule.connect(user1).createListing("Test Listing", "Details", ["https://test.com"], "Category")
      ).to.be.revertedWithCustomError(listingModule, "ListingAlreadyMinted");
    });
  });
});
