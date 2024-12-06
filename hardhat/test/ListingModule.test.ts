import { expect } from "chai";
import { ethers } from "hardhat";
import { ListingModule } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("ListingModule", function () {
  let listingModule: ListingModule;
  let owner: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();
    const ListingModule = await ethers.getContractFactory("ListingModule");
    listingModule = await ListingModule.deploy();
    await listingModule.waitForDeployment();
  });

  describe("Listing Creation", function () {
    it("Should create a listing correctly", async function () {
      const tx = await listingModule
        .connect(user1)
        .createListing(
          "Learning Solidity",
          "Completed advanced Solidity course",
          ["https://proof1.com", "https://proof2.com"],
          "Learning",
        );

      const listing = await listingModule.getListing(0);

      expect(listing.creator).to.equal(user1.address);
      expect(listing.title).to.equal("Learning Solidity");
      expect(listing.state).to.equal(0); // Active
      expect(listing.attestCount).to.equal(0);
      expect(listing.refuteCount).to.equal(0);
    });

    it("Should reject empty inputs", async function () {
      await expect(
        listingModule.createListing("", "details", ["proof"], "category"),
      ).to.be.revertedWithCustomError(listingModule, "EmptyTitle");

      await expect(
        listingModule.createListing("title", "", ["proof"], "category"),
      ).to.be.revertedWithCustomError(listingModule, "EmptyDetails");

      await expect(
        listingModule.createListing("title", "details", [], "category"),
      ).to.be.revertedWithCustomError(listingModule, "NoProofs");
    });
  });

  describe("Listing Archival", function () {
    beforeEach(async function () {
      await listingModule
        .connect(user1)
        .createListing("Original Listing", "Details", ["proof"], "category");
    });

    it("Should archive a listing correctly", async function () {
      await listingModule
        .connect(user1)
        .archiveListing(0, 1, "Updated version available");

      const listing = await listingModule.getListing(0);
      expect(listing.state).to.equal(1); // Archived
      expect(listing.linkedToId).to.equal(1);
      expect(listing.archiveNote).to.equal("Updated version available");
    });

    it("Should prevent non-creator from archiving", async function () {
      await expect(
        listingModule.connect(user2).archiveListing(0, 1, "Unauthorized"),
      ).to.be.revertedWithCustomError(listingModule, "UnauthorizedAccess");
    });
  });

  describe("View Functions", function () {
    beforeEach(async function () {
      await listingModule
        .connect(user1)
        .createListing("Test Listing", "Details", ["proof"], "category");
    });

    it("Should return correct listing status", async function () {
      expect(await listingModule.isListingActive(0)).to.be.true;
      expect(await listingModule.canEditListing(0)).to.be.true;
      expect(await listingModule.getTotalListings()).to.equal(1);
    });

    it("Should handle invalid listing IDs", async function () {
      await expect(listingModule.getListing(99)).to.be.revertedWithCustomError(
        listingModule,
        "InvalidListingId",
      );
    });
  });
});
