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

  describe("Listing Lifecycle", function () {
    it("Should handle complete listing lifecycle", async function () {
      // Create listing
      await capoep
        .connect(user1)
        .createListing(
          "Learning Solidity",
          "Completed advanced Solidity course",
          ["https://proof1.com"],
          "Learning",
        );

      // Verify initial state
      let listing = await capoep.getListing(0);
      expect(listing.state).to.equal(0); // Active

      // Get attestations
      await capoep.connect(user2).castVote(0, true, "Great work!");
      await capoep.connect(user3).castVote(0, true, "Verified!");

      // Check attestation count
      listing = await capoep.getListing(0);
      expect(listing.attestCount).to.equal(2);

      // Mint NFT
      await capoep.connect(user1).mintFromListing(0);

      // Verify final state
      listing = await capoep.getListing(0);
      expect(listing.state).to.equal(2); // Minted
    });
  });

  describe("Reputation System", function () {
    it("Should track reputation changes correctly", async function () {
      // Create listing
      await capoep
        .connect(user1)
        .createListing("Title", "Details", ["proof"], "Category");

      // Initial reputation should be 0
      expect(await capoep.getReputation(user1.address)).to.equal(0);

      // Attest to increase reputation
      await capoep.connect(user2).castVote(0, true, "Good!");
      expect(await capoep.getReputation(user1.address)).to.equal(1);

      // Refute to decrease reputation
      await capoep.connect(user3).castVote(0, false, "Not good");
      expect(await capoep.getReputation(user1.address)).to.equal(0);
    });
  });

  describe("Comments and Feedback", function () {
    it("Should handle comment voting and reputation", async function () {
      // Create listing
      await capoep
        .connect(user1)
        .createListing("Title", "Details", ["proof"], "Category");

      // Add comment
      await capoep.connect(user2).addComment(0, "Great work!", 0);

      // Vote on comment
      await capoep.connect(user3).voteOnComment(0, 0, true); // upvote

      // Check comment author reputation
      expect(await capoep.getReputation(user2.address)).to.equal(1);
    });
  });

  describe("NFT Metadata", function () {
    it("Should generate valid token URI", async function () {
      // Create and mint listing
      await capoep
        .connect(user1)
        .createListing("Learning Solidity", "Details", ["proof"], "Learning");
      await capoep.connect(user2).castVote(0, true, "Good!");
      await capoep.connect(user3).castVote(0, true, "Great!");
      await capoep.connect(user1).mintFromListing(0);

      // Get token URI
      const uri = await capoep.tokenURI(0);
      expect(uri).to.include("data:application/json;base64,");

      // Decode and verify metadata
      const base64Json = uri.split(",")[1];
      const jsonString = Buffer.from(base64Json, "base64").toString();
      console.log("Generated JSON:", jsonString); // Debug output
      const metadata = JSON.parse(jsonString);

      // Verify metadata structure
      expect(metadata).to.have.property("name", "Learning Solidity");
      expect(metadata).to.have.property("description", "Details");
      expect(metadata).to.have.property("attributes").that.is.an("array");
    });
  });
});
