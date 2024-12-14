import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { deployContracts, SAMPLE_LISTING } from "./helpers";
import {
  VotingModule,
  ListingModule,
  ReputationModule,
} from "../typechain-types";

describe("VotingModule", function () {
  let votingModule: VotingModule;
  let listingModule: ListingModule;
  let reputationModule: ReputationModule;
  let owner: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
  let listingId: number;

  beforeEach(async function () {
    const contracts = await deployContracts();
    votingModule = contracts.votingModule;
    listingModule = contracts.listingModule;
    reputationModule = contracts.reputationModule;
    owner = contracts.owner;
    user1 = contracts.user1;
    user2 = contracts.user2;

    // Set initial reputation for testing
    await reputationModule
      .connect(owner)
      .setInitialReputation(user2.address, 10);

    // Create a listing for testing
    await listingModule
      .connect(user1)
      .createListing(
        SAMPLE_LISTING.title,
        SAMPLE_LISTING.details,
        SAMPLE_LISTING.proofs,
        SAMPLE_LISTING.category,
      );
    listingId = 0;
  });

  describe("Voting Mechanics", function () {
    it("Should allow voting with sufficient reputation", async function () {
      const comment = "Great work!";
      await expect(
        votingModule.connect(user2).castVote(listingId, true, comment),
      )
        .to.emit(votingModule, "VoteCast")
        .withArgs(listingId, user2.address, true, comment);

      const [attestCount, refuteCount] =
        await votingModule.getVoteCount(listingId);
      expect(attestCount).to.equal(1);
      expect(refuteCount).to.equal(0);
    });

    it("Should prevent voting without comment", async function () {
      await expect(
        votingModule.connect(user2).castVote(listingId, true, ""),
      ).to.be.revertedWithCustomError(votingModule, "EmptyVoteComment");
    });

    it("Should prevent double voting", async function () {
      await votingModule.connect(user2).castVote(listingId, true, "First vote");
      await expect(
        votingModule.connect(user2).castVote(listingId, false, "Second vote"),
      ).to.be.revertedWithCustomError(votingModule, "AlreadyVoted");
    });

    it("Should prevent creator from voting on own listing", async function () {
      await expect(
        votingModule.connect(user1).castVote(listingId, true, "Self vote"),
      ).to.be.revertedWithCustomError(votingModule, "CannotVoteOwnListing");
    });

    it("Should track voter list correctly", async function () {
      await votingModule.connect(user2).castVote(listingId, true, "Vote 1");
      const voters = await votingModule.getVoterList(listingId);
      expect(voters).to.have.lengthOf(1);
      expect(voters[0]).to.equal(user2.address);
    });

    it("Should correctly track vote types", async function () {
      await votingModule
        .connect(user2)
        .castVote(listingId, true, "Attestation");
      const voteId = 0; // First vote
      const isAttestation = await votingModule.getVoteType(voteId);
      expect(isAttestation).to.be.true;
    });
  });

  describe("Vote Counts", function () {
    it("Should track attestations and refutations separately", async function () {
      await votingModule
        .connect(user2)
        .castVote(listingId, true, "Attestation");
      let [attestCount, refuteCount] =
        await votingModule.getVoteCount(listingId);
      expect(attestCount).to.equal(1);
      expect(refuteCount).to.equal(0);

      // Create another listing and vote with refutation
      await listingModule
        .connect(user1)
        .createListing(
          "Another Listing",
          SAMPLE_LISTING.details,
          SAMPLE_LISTING.proofs,
          SAMPLE_LISTING.category,
        );
      await votingModule.connect(user2).castVote(1, false, "Refutation");
      [attestCount, refuteCount] = await votingModule.getVoteCount(1);
      expect(attestCount).to.equal(0);
      expect(refuteCount).to.equal(1);
    });
  });

  it("Should prevent voting with insufficient reputation", async function () {
    // Set negative reputation
    await reputationModule
      .connect(owner)
      .updateReputation(user2.address, -15, "Penalty");

    await expect(
      votingModule.connect(user2).castVote(listingId, true, "Test vote"),
    ).to.be.revertedWithCustomError(votingModule, "InsufficientReputation");
  });

  it("Should update reputation after receiving votes", async function () {
    const initialRep = await reputationModule.getReputation(user1.address);
    await votingModule.connect(user2).castVote(listingId, true, "Attestation");

    const newRep = await reputationModule.getReputation(user1.address);
    expect(newRep).to.equal(initialRep + BigInt(1));
  });

  it("Should track vote history correctly", async function () {
    await votingModule.connect(user2).castVote(listingId, true, "First vote");
    const voters = await votingModule.getVoterList(listingId);
    const hasVoted = await votingModule.hasVoted(user2.address, listingId);

    expect(voters).to.have.lengthOf(1);
    expect(voters[0]).to.equal(user2.address);
    expect(hasVoted).to.be.true;
  });
});

describe("Vote Comments Integration", function () {
  it("Should create vote comment when voting", async function () {
    const voteComment = "Detailed explanation";
    const tx = await votingModule
      .connect(user2)
      .castVote(listingId, true, voteComment);
    const receipt = await tx.wait();

    const commentId = receipt.events?.find((e) => e.event === "VoteCast")?.args
      ?.commentId;
    expect(commentId).to.not.be.undefined;

    const comment = await contracts.commentsModule.getComment(
      listingId,
      commentId,
    );
    expect(comment.content).to.equal(voteComment);
    expect(comment.isVoteComment).to.be.true;
  });
});

describe("Edge Cases", function () {
  it("Should handle multiple votes on different listings", async function () {
    // Create second listing
    await listingModule
      .connect(user1)
      .createListing(
        "Second Listing",
        SAMPLE_LISTING.details,
        SAMPLE_LISTING.proofs,
        SAMPLE_LISTING.category,
      );

    await votingModule.connect(user2).castVote(0, true, "Vote on first");
    await votingModule.connect(user2).castVote(1, false, "Vote on second");

    const [attestCount1, refuteCount1] = await votingModule.getVoteCount(0);
    const [attestCount2, refuteCount2] = await votingModule.getVoteCount(1);

    expect(attestCount1).to.equal(1);
    expect(refuteCount2).to.equal(1);
  });

  it("Should fail gracefully on invalid listing IDs", async function () {
    await expect(
      votingModule.connect(user2).castVote(999, true, "Invalid listing"),
    ).to.be.revertedWithCustomError(listingModule, "InvalidListingId");
  });
});
