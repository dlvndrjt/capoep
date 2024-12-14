import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract } from "ethers";
import { deployContracts } from "./helpers";
import { ReputationModule } from "../typechain-types";

describe("ReputationModule", function () {
  let reputationModule: ReputationModule;
  let owner: any;
  let user1: any;
  let user2: any;
  let authorizedUpdater: any;

  beforeEach(async function () {
    const contracts = await deployContracts();
    reputationModule = contracts.reputationModule;
    owner = contracts.owner;
    user1 = contracts.user1;
    user2 = contracts.user2;
    [authorizedUpdater] = await ethers.getSigners();

    // Add an authorized updater for testing
    await reputationModule.connect(owner).addAuthorizedUpdater(authorizedUpdater.address);
  });

  describe("Authorization", function () {
    it("Should allow owner to add authorized updaters", async function () {
      await expect(reputationModule.connect(owner).addAuthorizedUpdater(user1.address))
        .to.emit(reputationModule, "UpdaterStatusChanged")
        .withArgs(user1.address, true);

      expect(await reputationModule.isAuthorizedUpdater(user1.address)).to.be.true;
    });

    it("Should allow owner to remove authorized updaters", async function () {
      await reputationModule.connect(owner).addAuthorizedUpdater(user1.address);
      await expect(reputationModule.connect(owner).removeAuthorizedUpdater(user1.address))
        .to.emit(reputationModule, "UpdaterStatusChanged")
        .withArgs(user1.address, false);

      expect(await reputationModule.isAuthorizedUpdater(user1.address)).to.be.false;
    });

    it("Should prevent non-owners from managing updaters", async function () {
      await expect(
        reputationModule.connect(user1).addAuthorizedUpdater(user2.address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("Reputation Updates", function () {
    it("Should allow authorized updaters to modify reputation", async function () {
      const points = 10;
      const reason = "Good contribution";

      await expect(
        reputationModule
          .connect(authorizedUpdater)
          .updateReputation(user1.address, points, reason)
      )
        .to.emit(reputationModule, "ReputationChanged")
        .withArgs(user1.address, 0, points, reason);

      expect(await reputationModule.getReputation(user1.address)).to.equal(points);
    });

    it("Should prevent unauthorized updates", async function () {
      await expect(
        reputationModule
          .connect(user2)
          .updateReputation(user1.address, 10, "Unauthorized update")
      ).to.be.revertedWithCustomError(reputationModule, "UnauthorizedUpdate");
    });

    it("Should handle negative reputation correctly", async function () {
      const points = -5;
      await reputationModule
        .connect(authorizedUpdater)
        .updateReputation(user1.address, points, "Penalty");

      expect(await reputationModule.getReputation(user1.address)).to.equal(points);
    });

    it("Should track reputation thresholds correctly", async function () {
      await reputationModule
        .connect(authorizedUpdater)
        .updateReputation(user1.address, 10, "Initial points");

      expect(await reputationModule.meetsReputationThreshold(user1.address, 5)).to.be.true;
      expect(await reputationModule.meetsReputationThreshold(user1.address, 15)).to.be.false;
    });
  });

  describe("Specialized Updates", function () {
    it("Should handle vote-based reputation updates", async function () {
      await expect(
        reputationModule.connect(authorizedUpdater).updateReputationFromVote(user1.address, true)
      )
        .to.emit(reputationModule, "ReputationChanged")
        .withArgs(user1.address, 0, 1, "Received attestation");

      await expect(
        reputationModule.connect(authorizedUpdater).updateReputationFromVote(user1.address, false)
      )
        .to.emit(reputationModule, "ReputationChanged")
        .withArgs(user1.address, 1, 0, "Received refutation");
    });

    it("Should handle comment feedback reputation updates", async function () {
      await expect(
        reputationModule
          .connect(authorizedUpdater)
          .updateReputationFromCommentFeedback(user1.address, true)
      )
        .to.emit(reputationModule, "ReputationChanged")
        .withArgs(user1.address, 0, 1, "Comment upvoted");

      await expect(
        reputationModule
          .connect(authorizedUpdater)
          .updateReputationFromCommentFeedback(user1.address, false)
      )
        .to.emit(reputationModule, "ReputationChanged")
        .withArgs(user1.address, 1, 0, "Comment downvoted");
    });
  });

  describe("Initial Reputation", function () {
    it("Should allow owner to set initial reputation", async function () {
      const initialRep = 5;
      await expect(
        reputationModule.connect(owner).setInitialReputation(user1.address, initialRep)
      )
        .to.emit(reputationModule, "ReputationChanged")
        .withArgs(user1.address, 0, initialRep, "Initial reputation set");

      expect(await reputationModule.getReputation(user1.address)).to.equal(initialRep);
    });

    it("Should prevent setting initial reputation twice", async function () {
      await reputationModule.connect(owner).setInitialReputation(user1.address, 5);
      await expect(
        reputationModule.connect(owner).setInitialReputation(user1.address, 10)
      ).to.be.revertedWith("Reputation already set");
    });
  });
});