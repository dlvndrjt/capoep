import { expect } from "chai";
import { ethers } from "hardhat";
import { CAPOEP } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("CAPOEP", function () {
  let capoep: CAPOEP;
  let owner: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
  let user3: SignerWithAddress;

  beforeEach(async function () {
    [owner, user1, user2, user3] = await ethers.getSigners();

    const CAPOEP = await ethers.getContractFactory("CAPOEP");
    capoep = await CAPOEP.deploy(owner.address);
    await capoep.waitForDeployment();
  });

  describe("Listing Creation and Management", function () {
    it("Should create a new listing correctly", async function () {
      const tx = await capoep
        .connect(user1)
        .createListing(
          "Learning Solidity",
          "Completed advanced Solidity course",
          ["https://proof1.com", "https://proof2.com"],
          "Learning",
        );

      const listingId = 0; // First listing
      const listing = await capoep.getListing(listingId);

      expect(listing.creator).to.equal(user1.address);
      expect(listing.title).to.equal("Learning Solidity");
      expect(listing.state).to.equal(0); // Active state
      expect(listing.attestCount).to.equal(0);
      expect(listing.refuteCount).to.equal(0);
    });

    it("Should allow voting on listings", async function () {
      // Create listing
      await capoep
        .connect(user1)
        .createListing(
          "Learning Solidity",
          "Completed advanced Solidity course",
          ["https://proof1.com"],
          "Learning",
        );

      // Cast votes
      await capoep.connect(user2).castVote(0, true, "Great work!");
      await capoep.connect(user3).castVote(0, true, "Verified!");

      const listing = await capoep.getListing(0);
      expect(listing.attestCount).to.equal(2);
    });

    it("Should mint NFT after sufficient attestations", async function () {
      // Create listing
      await capoep
        .connect(user1)
        .createListing(
          "Learning Solidity",
          "Completed advanced Solidity course",
          ["https://proof1.com"],
          "Learning",
        );

      // Get attestations
      await capoep.connect(user2).castVote(0, true, "Great work!");
      await capoep.connect(user3).castVote(0, true, "Verified!");

      // Mint NFT
      await capoep.connect(user1).mintFromListing(0);

      // Verify NFT ownership
      expect(await capoep.ownerOf(0)).to.equal(user1.address);

      // Verify listing state
      const listing = await capoep.getListing(0);
      expect(listing.state).to.equal(2); // Minted state
    });
  });

  describe("Comments and Feedback", function () {
    it("Should handle comments correctly", async function () {
      // Create listing
      await capoep
        .connect(user1)
        .createListing(
          "Learning Solidity",
          "Details",
          ["https://proof1.com"],
          "Learning",
        );

      // Add comment
      await capoep.connect(user2).addComment(0, "Great work!", 0);

      const comments = await capoep.getListingComments(0);
      expect(comments.length).to.equal(1);
      expect(comments[0].author).to.equal(user2.address);
      expect(comments[0].content).to.equal("Great work!");
    });
  });
});
