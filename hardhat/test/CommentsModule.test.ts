import { ethers } from "hardhat";
import { expect } from "chai";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { CommentsModule, ReputationModule } from "../typechain-types";
import { Contract } from "ethers";

describe("CommentsModule", function () {
  let commentsModule: CommentsModule;
  let reputationModule: ReputationModule;
  let mockListing: Contract;
  let owner: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
  let user3: SignerWithAddress;
  let mockListingAddress: string;

  beforeEach(async function () {
    [owner, user1, user2, user3] = await ethers.getSigners();

    // Deploy mock listing contract
    const MockListing = await ethers.getContractFactory("MockListing");
    mockListing = await MockListing.deploy();
    await mockListing.waitForDeployment();
    mockListingAddress = await mockListing.getAddress();

    // Deploy ReputationModule
    const ReputationModule = await ethers.getContractFactory("ReputationModule");
    reputationModule = await ReputationModule.deploy(owner.address);
    await reputationModule.waitForDeployment();

    // Add owner and other necessary addresses as authorized updaters
    await reputationModule.connect(owner).addAuthorizedUpdater(owner.address);

    // Deploy CommentsModule
    const CommentsModule = await ethers.getContractFactory("CommentsModule");
    commentsModule = await CommentsModule.deploy(
      mockListingAddress,
      await reputationModule.getAddress()
    );
    await commentsModule.waitForDeployment();

    // Add CommentsModule as an authorized updater for reputation
    await reputationModule.connect(owner).addAuthorizedUpdater(await commentsModule.getAddress());

    // Add initial reputation to users
    await reputationModule.connect(owner).updateReputation(user2.address, 100n, "Initial reputation");
    await reputationModule.connect(owner).updateReputation(user3.address, 100n, "Initial reputation");
  });

  describe("Comment Creation", function () {
    it("Should create a comment correctly", async function () {
      const tx = await commentsModule.connect(user2).addComment(0, "Test comment", 0);
      const receipt = await tx.wait();
      const commentId = receipt?.logs[0].args[1];
      
      const comment = await commentsModule.getComment(0, commentId);
      expect(comment.content).to.equal("Test comment");
      expect(comment.author).to.equal(user2.address);
    });

    it("Should handle nested comments", async function () {
      const parentTx = await commentsModule.connect(user2).addComment(0, "Parent comment", 0);
      const parentReceipt = await parentTx.wait();
      const parentId = parentReceipt?.logs[0].args[1];

      const childTx = await commentsModule.connect(user2).addComment(0, "Child comment", parentId);
      const childReceipt = await childTx.wait();
      const childId = childReceipt?.logs[0].args[1];

      const childComment = await commentsModule.getComment(0, childId);
      expect(childComment.parentId).to.equal(parentId);
    });

    it("Should reject empty comments", async function () {
      try {
        await commentsModule.connect(user2).addComment(0, "", 0);
        expect.fail("Should have thrown an error");
      } catch (error: any) {
        expect(error.message).to.include("EmptyComment");
      }
    });

    it("Should reject invalid parent comments", async function () {
      try {
        await commentsModule.connect(user2).addComment(0, "Test comment", 999);
        expect.fail("Should have thrown an error");
      } catch (error: any) {
        expect(error.message).to.include("InvalidParentComment");
      }
    });
  });

  describe("Comment Voting", function () {
    let commentId: bigint;

    beforeEach(async function () {
      const tx = await commentsModule.connect(user2).addComment(0, "Test comment", 0);
      const receipt = await tx.wait();
      commentId = receipt?.logs[0].args[1];
    });

    it("Should handle comment votes correctly", async function () {
      await commentsModule.connect(user1).voteOnComment(0, commentId, true);
      const comment = await commentsModule.getComment(0, commentId);
      expect(comment.upvotes.toString()).to.equal("1");
    });

    it("Should prevent double voting", async function () {
      await commentsModule.connect(user1).voteOnComment(0, commentId, true);
      try {
        await commentsModule.connect(user1).voteOnComment(0, commentId, false);
        expect.fail("Should have thrown an error");
      } catch (error: any) {
        expect(error.message).to.include("AlreadyVotedOnComment");
      }
    });
  });

  describe("Error Cases", function () {
    it("Should reject votes on non-existent comments", async function () {
      try {
        await commentsModule.connect(user1).voteOnComment(0, 999n, true);
        expect.fail("Should have thrown an error");
      } catch (error: any) {
        expect(error.message).to.include("CommentDoesNotExist");
      }
    });
  });
});
