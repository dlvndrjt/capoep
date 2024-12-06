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

  beforeEach(async function () {
    [owner, user1, user2, user3] = await ethers.getSigners();
    const VotingModule = await ethers.getContractFactory("VotingModule");
    votingModule = await VotingModule.deploy();
    await votingModule.waitForDeployment();
  });

  describe("Voting Functions", function () {
    it("Should cast a vote correctly", async function () {
      await votingModule.connect(user1).castVote(0, true, "Great work!");
      const vote = await votingModule.getVote(0, user1.address);
      
      expect(vote.isAttest).to.be.true;
      expect(vote.comment).to.equal("Great work!");
      expect(vote.upvotes).to.equal(0);
      expect(vote.downvotes).to.equal(0);
    });

    it("Should track voters correctly", async function () {
      await votingModule.connect(user1).castVote(0, true, "First vote");
      await votingModule.connect(user2).castVote(0, false, "Second vote");
      
      const voters = await votingModule.getVoters(0);
      expect(voters).to.have.length(2);
      expect(voters).to.include(user1.address);
      expect(voters).to.include(user2.address);
    });

    it("Should handle vote feedback correctly", async function () {
      await votingModule.connect(user1).castVote(0, true, "Original vote");
      await votingModule.connect(user2).giveVoteFeedback(0, user1.address, true);
      
      const vote = await votingModule.getVote(0, user1.address);
      expect(vote.upvotes).to.equal(1);
      expect(vote.downvotes).to.equal(0);
    });
  });

  describe("Error Cases", function () {
    it("Should prevent double voting", async function () {
      await votingModule.connect(user1).castVote(0, true, "First attempt");
      await expect(
        votingModule.connect(user1).castVote(0, false, "Second attempt")
      ).to.be.revertedWithCustomError(votingModule, "AlreadyVoted");
    });

    it("Should require non-empty comments", async function () {
      await expect(
        votingModule.connect(user1).castVote(0, true, "")
      ).to.be.revertedWithCustomError(votingModule, "EmptyComment");
    });
  });
});
