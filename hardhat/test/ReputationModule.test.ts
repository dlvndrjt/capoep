import { expect } from "chai";
import { ethers } from "hardhat";
import { ReputationModule } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("ReputationModule", function () {
  let reputationModule: ReputationModule;
  let owner: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
  let updater: SignerWithAddress;

  beforeEach(async function () {
    [owner, user1, user2, updater] = await ethers.getSigners();
    const ReputationModule =
      await ethers.getContractFactory("ReputationModule");
    reputationModule = await ReputationModule.deploy();
    await reputationModule.waitForDeployment();

    // Authorize updater
    await reputationModule.addAuthorizedUpdater(updater.address);
  });

  describe("Reputation Updates", function () {
    it("Should update reputation correctly", async function () {
      await reputationModule
        .connect(updater)
        .updateReputation(user1.address, 5, "Good contribution");
      expect(await reputationModule.getReputation(user1.address)).to.equal(5);
    });

    it("Should handle negative reputation", async function () {
      await reputationModule
        .connect(updater)
        .updateReputation(user1.address, -3, "Poor behavior");
      expect(await reputationModule.getReputation(user1.address)).to.equal(-3);
    });

    it("Should emit ReputationChanged event", async function () {
      await expect(
        reputationModule
          .connect(updater)
          .updateReputation(user1.address, 1, "Test"),
      )
        .to.emit(reputationModule, "ReputationChanged")
        .withArgs(user1.address, 1, "Test");
    });
  });

  describe("Threshold Checks", function () {
    it("Should correctly check reputation thresholds", async function () {
      await reputationModule
        .connect(updater)
        .updateReputation(user1.address, 10, "Initial rep");

      expect(await reputationModule.meetsReputationThreshold(user1.address, 5))
        .to.be.true;
      expect(await reputationModule.meetsReputationThreshold(user1.address, 15))
        .to.be.false;
    });
  });

  describe("Authorization", function () {
    it("Should prevent unauthorized updates", async function () {
      await expect(
        reputationModule
          .connect(user1)
          .updateReputation(user2.address, 1, "Unauthorized"),
      ).to.be.revertedWithCustomError(reputationModule, "UnauthorizedUpdate");
    });

    it("Should allow adding and removing updaters", async function () {
      await reputationModule.addAuthorizedUpdater(user1.address);
      await reputationModule
        .connect(user1)
        .updateReputation(user2.address, 1, "Now authorized");

      await reputationModule.removeAuthorizedUpdater(user1.address);
      await expect(
        reputationModule
          .connect(user1)
          .updateReputation(user2.address, 1, "No longer authorized"),
      ).to.be.revertedWithCustomError(reputationModule, "UnauthorizedUpdate");
    });
  });
});
