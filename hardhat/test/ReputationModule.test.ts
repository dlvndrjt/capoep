import { expect } from "chai";
import { ethers } from "hardhat";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { ReputationModule } from "../typechain-types/contracts/modules/ReputationModule";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("ReputationModule", function () {
  let reputationModule: ReputationModule;
  let owner: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
  let user3: SignerWithAddress;

  beforeEach(async function () {
    [owner, user1, user2, user3] = await ethers.getSigners();
    const ReputationModule = await ethers.getContractFactory("ReputationModule");
    reputationModule = await ReputationModule.deploy(owner.address);
    await reputationModule.waitForDeployment();
    
    // Add owner as an updater
    await reputationModule.connect(owner).addAuthorizedUpdater(owner.address);
  });

  describe("Reputation Updates", function () {
    it("Should update reputation correctly", async function () {
      await reputationModule.connect(owner).updateReputation(user1.address, 10n, "Test update");
      const reputation = await reputationModule.getReputation(user1.address);
      expect(reputation).to.equal(10n);
    });

    it("Should handle negative reputation", async function () {
      await reputationModule.connect(owner).updateReputation(user1.address, -5n, "Negative update");
      const reputation = await reputationModule.getReputation(user1.address);
      expect(reputation).to.equal(-5n);
    });

    it("Should emit ReputationChanged event", async function () {
      await expect(reputationModule.connect(owner).updateReputation(user1.address, 10n, "Test event"))
        .to.emit(reputationModule, "ReputationChanged")
        .withArgs(user1.address, 10n, "Test event");
    });
  });

  describe("Threshold Checks", function () {
    it("Should correctly check reputation thresholds", async function () {
      await reputationModule.connect(owner).updateReputation(user1.address, 50n, "Threshold test");
      const isAboveThreshold = await reputationModule.meetsReputationThreshold(user1.address, 40n);
      expect(isAboveThreshold).to.be.true;
    });
  });

  describe("Authorization", function () {
    it("Should prevent unauthorized updates", async function () {
      await expect(
        reputationModule.connect(user1).updateReputation(user2.address, 10n, "Test update")
      ).to.be.revertedWithCustomError(reputationModule, "UnauthorizedUpdate");
    });

    it("Should allow adding and removing updaters", async function () {
      // Add user2 as an authorized updater
      await reputationModule.connect(owner).addAuthorizedUpdater(user2.address);
      
      // Remove user2 as an authorized updater
      await reputationModule.connect(owner).removeAuthorizedUpdater(user2.address);
      
      // Verify user2 can no longer update reputation
      await expect(
        reputationModule.connect(user2).updateReputation(user3.address, 10n, "Test update")
      ).to.be.revertedWithCustomError(reputationModule, "UnauthorizedUpdate");
    });
  });
});
