import { expect } from "chai";
import { ethers } from "hardhat";
import { CommentsModule } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("CommentsModule", function () {
  let commentsModule: CommentsModule;
  let owner: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
  let user3: SignerWithAddress;

  beforeEach(async function () {
    [owner, user1, user2, user3] = await ethers.getSigners();
    const CommentsModule = await ethers.getContractFactory("CommentsModule");
    commentsModule = await CommentsModule.deploy();
    await commentsModule.waitForDeployment();
  });

  describe("Comment Creation", function () {
    it("Should create a comment correctly", async function () {
      await commentsModule.connect(user1).addComment(0, "Great listing!", 0);
      const comments = await commentsModule.getListingComments(0);

      expect(comments).to.have.length(1);
      expect(comments[0].author).to.equal(user1.address);
      expect(comments[0].content).to.equal("Great listing!");
      expect(comments[0].parentId).to.equal(0);
    });

    it("Should handle nested comments", async function () {
      const tx = await commentsModule
        .connect(user1)
        .addComment(0, "Parent comment", 0);
      const receipt = await tx.wait();
      const event = receipt?.logs[0];
      const parentCommentId = event?.args?.commentId;

      await commentsModule
        .connect(user2)
        .addComment(0, "Child comment", parentCommentId);

      const comments = await commentsModule.getListingComments(0);
      expect(comments).to.have.length(2);
      expect(comments[1].parentId).to.equal(parentCommentId);
    });
  });

  describe("Comment Voting", function () {
    it("Should handle upvotes correctly", async function () {
      await commentsModule.connect(user1).addComment(0, "Test comment", 0);
      await commentsModule.connect(user2).voteOnComment(0, 0, true);

      const comments = await commentsModule.getListingComments(0);
      expect(comments[0].upvotes).to.equal(1);
      expect(comments[0].downvotes).to.equal(0);
    });

    it("Should prevent double voting", async function () {
      await commentsModule.connect(user1).addComment(0, "Test comment", 0);
      await commentsModule.connect(user2).voteOnComment(0, 0, true);

      await expect(
        commentsModule.connect(user2).voteOnComment(0, 0, true),
      ).to.be.revertedWithCustomError(commentsModule, "AlreadyVotedOnComment");
    });
  });

  describe("Error Cases", function () {
    it("Should reject empty comments", async function () {
      await expect(
        commentsModule.connect(user1).addComment(0, "", 0),
      ).to.be.revertedWithCustomError(commentsModule, "EmptyComment");
    });

    it("Should reject votes on non-existent comments", async function () {
      await expect(
        commentsModule.connect(user1).voteOnComment(0, 999, true),
      ).to.be.revertedWithCustomError(commentsModule, "CommentNotFound");
    });
  });
});
