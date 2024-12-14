import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract } from "ethers";
import { deployContracts, SAMPLE_LISTING } from "./helpers";
import { CommentsModule, ListingModule } from "../typechain-types";

describe("CommentsModule", function () {
  let commentsModule: CommentsModule;
  let listingModule: ListingModule;
  let owner: any;
  let user1: any;
  let user2: any;
  let listingId: number;

  beforeEach(async function () {
    const contracts = await deployContracts();
    commentsModule = contracts.commentsModule;
    listingModule = contracts.listingModule;
    owner = contracts.owner;
    user1 = contracts.user1;
    user2 = contracts.user2;

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

  describe("General Comments", function () {
    it("Should allow adding comments to listings", async function () {
      const content = "Great achievement!";
      await expect(
        commentsModule.connect(user2).addComment(listingId, content, 0),
      )
        .to.emit(commentsModule, "CommentCreated")
        .withArgs(listingId, 0, user2.address, 0);
    });

    it("Should prevent empty comments", async function () {
      await expect(
        commentsModule.connect(user2).addComment(listingId, "", 0),
      ).to.be.revertedWithCustomError(commentsModule, "EmptyComment");
    });

    it("Should support nested comments", async function () {
      // Add parent comment
      await commentsModule
        .connect(user2)
        .addComment(listingId, "Parent comment", 0);
      const parentId = 0;

      // Add reply to parent
      await expect(
        commentsModule.connect(user1).addComment(listingId, "Reply", parentId),
      )
        .to.emit(commentsModule, "CommentCreated")
        .withArgs(listingId, 1, user1.address, parentId);

      const children = await commentsModule.getChildComments(
        listingId,
        parentId,
      );
      expect(children).to.have.lengthOf(1);
      expect(children[0].content).to.equal("Reply");
    });
  });

  describe("Comment Voting", function () {
    let commentId: number;

    beforeEach(async function () {
      await commentsModule
        .connect(user2)
        .addComment(listingId, "Test comment", 0);
      commentId = 0;
    });

    it("Should allow voting on comments", async function () {
      await expect(
        commentsModule.connect(user1).voteOnComment(listingId, commentId, true),
      )
        .to.emit(commentsModule, "CommentVoted")
        .withArgs(commentId, user1.address, true);
    });

    it("Should prevent double voting on comments", async function () {
      await commentsModule
        .connect(user1)
        .voteOnComment(listingId, commentId, true);
      await expect(
        commentsModule
          .connect(user1)
          .voteOnComment(listingId, commentId, false),
      ).to.be.revertedWithCustomError(commentsModule, "AlreadyVotedOnComment");
    });
  });

  describe("Vote Comments", function () {
    it("Should correctly identify vote comments", async function () {
      // Only voting module can create vote comments
      const voteId = 0;
      await commentsModule
        .connect(owner)
        .addVoteComment(listingId, voteId, "Vote comment", user2.address);

      expect(await commentsModule.isVoteComment(0)).to.be.true;
      const [returnedVoteId, voter, isAttestation] =
        await commentsModule.getVoteCommentDetails(0);
      expect(returnedVoteId).to.equal(voteId);
      expect(voter).to.equal(user2.address);
    });
  });
});
