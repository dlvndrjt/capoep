import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract } from "ethers";
import { deployContracts, SAMPLE_LISTING } from "./helpers";
import {
  CAPOEP,
  ListingModule,
  VotingModule,
  CommentsModule,
  ReputationModule,
} from "../typechain-types";

describe("Integration Tests", function () {
  let capoep: CAPOEP;
  let listingModule: ListingModule;
  let votingModule: VotingModule;
  let commentsModule: CommentsModule;
  let reputationModule: ReputationModule;
  let owner: any;
  let creator: any;
  let voter: any;
  let commenter: any;
  let listingId: number;

  beforeEach(async function () {
    const contracts = await deployContracts();
    capoep = contracts.capoep;
    listingModule = contracts.listingModule;
    votingModule = contracts.votingModule;
    commentsModule = contracts.commentsModule;
    reputationModule = contracts.reputationModule;
    owner = contracts.owner;
    [creator, voter, commenter] = await ethers.getSigners();

    // Create a listing for testing
    await listingModule
      .connect(creator)
      .createListing(
        SAMPLE_LISTING.title,
        SAMPLE_LISTING.details,
        SAMPLE_LISTING.proofs,
        SAMPLE_LISTING.category,
      );
    listingId = 0;
  });

  describe("Voting and Comments Flow", function () {
    it("Should handle complete voting flow with comments", async function () {
      // Cast a vote with comment
      const voteComment = "Great achievement!";
      await expect(
        votingModule.connect(voter).castVote(listingId, true, voteComment),
      )
        .to.emit(votingModule, "VoteCast")
        .withArgs(listingId, voter.address, true, voteComment);

      // Verify vote was recorded
      expect(await votingModule.hasVoted(voter.address, listingId)).to.be.true;
      const [attestCount, refuteCount] =
        await votingModule.getVoteCount(listingId);
      expect(attestCount).to.equal(1);
      expect(refuteCount).to.equal(0);

      // Verify vote comment was created
      const isVoteComment = await commentsModule.isVoteComment(0);
      expect(isVoteComment).to.be.true;

      // Add a regular comment
      const regularComment = "Additional feedback";
      await commentsModule
        .connect(commenter)
        .addComment(listingId, regularComment, 0);

      // Vote on the regular comment
      await commentsModule.connect(voter).voteOnComment(listingId, 1, true);

      // Verify reputation changes
      const creatorRep = await reputationModule.getReputation(creator.address);
      const commenterRep = await reputationModule.getReputation(
        commenter.address,
      );
      expect(creatorRep).to.be.gt(0); // Creator got reputation from attestation
      expect(commenterRep).to.be.gt(0); // Commenter got reputation from upvote
    });

    it("Should handle listing versioning with votes", async function () {
      // Cast initial votes
      await votingModule.connect(voter).castVote(listingId, true, "First vote");

      // Try to edit listing after votes
      await expect(
        listingModule
          .connect(creator)
          .editListing(
            listingId,
            "Updated Title",
            SAMPLE_LISTING.details,
            SAMPLE_LISTING.proofs,
            SAMPLE_LISTING.category,
          ),
      ).to.be.revertedWithCustomError(listingModule, "ListingHasVotes");

      // Create new version
      await listingModule
        .connect(creator)
        .createNewVersion(
          listingId,
          "Updated Title",
          SAMPLE_LISTING.details,
          SAMPLE_LISTING.proofs,
          SAMPLE_LISTING.category,
          "Updated with more details",
        );

      // Verify original listing is archived
      const originalListing = await listingModule.getListing(listingId);
      expect(originalListing.state).to.equal(2); // Archived

      // Verify new version is active
      const newListing = await listingModule.getListing(1);
      expect(newListing.state).to.equal(0); // Active
      expect(newListing.title).to.equal("Updated Title");
    });
  });

  describe("Reputation and Voting Restrictions", function () {
    it("Should enforce reputation requirements for voting", async function () {
      // Set negative reputation
      await reputationModule
        .connect(owner)
        .updateReputation(voter.address, -15, "Penalty");

      // Try to vote with insufficient reputation
      await expect(
        votingModule.connect(voter).castVote(listingId, true, "Test vote"),
      ).to.be.revertedWithCustomError(votingModule, "InsufficientReputation");

      // Improve reputation
      await reputationModule
        .connect(owner)
        .updateReputation(voter.address, 20, "Reputation restored");

      // Should now be able to vote
      await expect(
        votingModule.connect(voter).castVote(listingId, true, "Test vote"),
      ).to.not.be.reverted;
    });
  });

  describe("Comment Threading and Voting", function () {
    it("Should handle nested comments with votes", async function () {
      // Add parent comment
      await commentsModule
        .connect(commenter)
        .addComment(listingId, "Parent comment", 0);

      // Add reply
      await commentsModule
        .connect(voter)
        .addComment(listingId, "Reply to parent", 0);

      // Vote on both comments
      await commentsModule.connect(voter).voteOnComment(listingId, 0, true);
      await commentsModule.connect(commenter).voteOnComment(listingId, 1, true);

      // Verify comment structure
      const children = await commentsModule.getChildComments(listingId, 0);
      expect(children).to.have.lengthOf(1);
      expect(children[0].content).to.equal("Reply to parent");

      // Verify reputation changes
      const commenterRep = await reputationModule.getReputation(
        commenter.address,
      );
      const voterRep = await reputationModule.getReputation(voter.address);
      expect(commenterRep).to.be.gt(0);
      expect(voterRep).to.be.gt(0);
    });
  });
});
