import { expect } from "chai";
import { ethers } from "hardhat";
import { VotingModule } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("VotingModule", function () {
  let votingModule: VotingModule;
  let owner: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
  let user3: SignerWithAddress;
  let reputationModule: any;

  beforeEach(async function () {
    [owner, user1, user2, user3] = await ethers.getSigners();

    // Deploy ReputationModule
    const ReputationModule = await ethers.getContractFactory("ReputationModule");
    reputationModule = await ReputationModule.deploy(owner.address);
    await reputationModule.waitForDeployment();

    // Deploy VotingModule with ReputationModule address
    const VotingModule = await ethers.getContractFactory("VotingModule");
    votingModule = await VotingModule.deploy(await reputationModule.getAddress());
    await votingModule.waitForDeployment();

    // Add VotingModule as an authorized updater for ReputationModule
    await reputationModule.connect(owner).addAuthorizedUpdater(await votingModule.getAddress());

    // Add initial reputation to users
    await reputationModule.connect(owner).updateReputation(user2.address, 100n, "Initial reputation");
    await reputationModule.connect(owner).updateReputation(user3.address, 100n, "Initial reputation");
  });

  describe("Voting Functions", function () {
    beforeEach(async function () {
      // Create a mock listing for testing
      const MockListing = await ethers.getContractFactory("ListingModule");
      const mockListing = await MockListing.deploy();
      await mockListing.waitForDeployment();

      // Create a listing
      await mockListing.connect(user1).createListing(
        "Test Listing",
        "Test Details",
        ["https://test.com"],
        "Education"
      );
    });

    it("Should cast a vote correctly", async function () {
      await votingModule.connect(user2).castVote(0, true, "Great listing!");
      const vote = await votingModule.getVote(0, user2.address);
      expect(vote.isAttest).to.be.true;
      expect(vote.comment).to.equal("Great listing!");
    });

    it("Should track voters correctly", async function () {
      await votingModule.connect(user2).castVote(0, true, "Great listing!");
      await votingModule.connect(user3).castVote(0, false, "Not convinced.");

      const voters = await votingModule.getVoters(0);
      expect(voters).to.have.length(2);
      expect(voters).to.include(user2.address);
      expect(voters).to.include(user3.address);
    });

    it("Should handle vote feedback correctly", async function () {
      await votingModule.connect(user2).castVote(0, true, "Great listing!");
      const voteCounts = await votingModule.getVoteCounts(0);
      expect(voteCounts.attestCount).to.equal(1);
      expect(voteCounts.refuteCount).to.equal(0);
    });
  });

  describe("Error Cases", function () {
    beforeEach(async function () {
      // Create a mock listing for testing
      const MockListing = await ethers.getContractFactory("ListingModule");
      const mockListing = await MockListing.deploy();
      await mockListing.waitForDeployment();

      // Create a listing
      await mockListing.connect(user1).createListing(
        "Test Listing",
        "Test Details",
        ["https://test.com"],
        "Education"
      );
    });

    it("Should prevent double voting", async function () {
      await votingModule.connect(user2).castVote(0, true, "First vote");
      await expect(
        votingModule.connect(user2).castVote(0, false, "Second vote")
      ).to.be.revertedWithCustomError(votingModule, "AlreadyVoted");
    });

    it("Should require non-empty comments", async function () {
      await expect(
        votingModule.connect(user2).castVote(0, true, "")
      ).to.be.revertedWithCustomError(votingModule, "EmptyVoteComment");
    });

    it("Should prevent voting with insufficient reputation", async function () {
      await expect(
        votingModule.connect(user1).castVote(0, true, "Test vote")
      ).to.be.revertedWithCustomError(votingModule, "InsufficientReputation");
    });

    it("Should prevent voting on own listing", async function () {
      await expect(
        votingModule.connect(user1).castVote(0, true, "Own listing vote")
      ).to.be.revertedWithCustomError(votingModule, "CannotVoteOwnListing");
    });
  });
});
