import { expect } from "chai";
import { ethers } from "hardhat";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { ContractTransactionResponse } from "ethers";
import { CAPOEP } from "../typechain-types/contracts/CAPOEP";
import { MetadataModule } from "../typechain-types/contracts/modules/MetadataModule";
import { ReputationModule } from "../typechain-types/contracts/modules/ReputationModule";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { parseEther } from "ethers";

describe("CAPOEP Integration", function () {
  let capoep: CAPOEP;
  let metadata: MetadataModule;
  let reputationModule: ReputationModule;
  let owner: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
  let user3: SignerWithAddress;

  // Enum values from contract
  enum ListingState {
    Active = 0,
    Archived = 1,
    Minted = 2
  }

  beforeEach(async function () {
    [owner, user1, user2, user3] = await ethers.getSigners();

    // Deploy MetadataModule first
    console.log("Deploying MetadataModule...");
    const MetadataModule = await ethers.getContractFactory("MetadataModule");
    try {
        metadata = await MetadataModule.deploy(); // Deploy the contract
        await metadata.waitForDeployment(); // Wait for the transaction to be mined
        console.log("MetadataModule deployed at:", metadata.address);
    } catch (error) {
        console.error("Error deploying MetadataModule:", error);
        throw error;
    }
    expect(metadata.address).to.not.be.undefined; // Ensure address is defined

    // Deploy CAPOEP with metadata address
    console.log("Deploying CAPOEP with owner:", owner.address);
    const CAPOEP = await ethers.getContractFactory("CAPOEP");
    capoep = await CAPOEP.deploy(owner.address);
    if (capoep.deployTransaction) {
        try {
            const capoepTx = await capoep.deployTransaction.wait();
            console.log("CAPOEP deployed at:", capoep.address);
            console.log("CAPOEP deployment transaction receipt:", capoepTx);
        } catch (error) {
            console.error("Error during CAPOEP deployment:", error);
            throw error; // Re-throw to fail the test if deployment fails
        }
    } else {
        console.error("CAPOEP deployment transaction is undefined.");
    }

    console.log("ReputationModule address:", await capoep.getReputationModule());
    console.log("VotingModule address:", await capoep.getVotingModule());
    console.log("CommentsModule address:", await capoep.getCommentsModule());
    console.log("ListingModule address:", await capoep.getListingModule());

    // Get reputation module
    const reputationModuleAddress = await capoep.getReputationModule();
    console.log("ReputationModule address:", reputationModuleAddress);
    reputationModule = await ethers.getContractAt("ReputationModule", reputationModuleAddress);

    // Add authorized updaters to reputation module
    console.log("Adding authorized updaters...");
    await reputationModule.connect(owner).addAuthorizedUpdater(owner.address);
    await reputationModule.connect(owner).addAuthorizedUpdater(await capoep.getAddress());
    await reputationModule.connect(owner).addAuthorizedUpdater(user2.address);
    await reputationModule.connect(owner).addAuthorizedUpdater(user3.address);
    console.log("Authorized updaters added.");

    // Ensure initial reputation is set
    console.log("Setting initial reputation for user2 and user3...");
    await reputationModule.connect(owner).setInitialReputation(user2.address, 10);
    await reputationModule.connect(owner).setInitialReputation(user3.address, 10);
    console.log("Initial reputations set.");
  });

  describe("Listing Lifecycle", function () {
    it("Should handle complete listing lifecycle with versioning", async function () {
      // Create initial listing
      const firstListingTx = await capoep.connect(user1).createListing(
        "Learning Solidity",
        "Completed advanced Solidity course",
        ["https://proof1.com"],
        "Learning"
      );
      await firstListingTx.wait();

      console.log("Initial listing created");

      // Check initial listing state
      const initialListing = await capoep.getListing(0n);
      expect(initialListing.state).to.be.eq(BigInt(ListingState.Active));

      console.log("Initial listing state:", initialListing.state);

      // Create new version and archive old listing
      const newListingTx = await capoep.connect(user1).createListing(
        "Advanced Solidity Mastery",
        "Completed expert-level course and built dApp",
        ["https://proof1.com", "https://proof2.com"],
        "Learning"
      );
      await newListingTx.wait();

      console.log("New listing created");

      const archiveTx = await capoep.connect(user1).archiveListing(0n, 1n, "Updated with more achievements");
      await archiveTx.wait();

      console.log("Listing archived");

      // Verify archived listing
      const archivedListing = await capoep.getListing(0n);
      expect(archivedListing.state).to.be.eq(BigInt(ListingState.Archived));
      expect(archivedListing.linkedToId).to.be.eq(1n);

      console.log("Archived listing state:", archivedListing.state);
      console.log("Linked listing ID:", archivedListing.linkedToId);
    });

    it("Should handle reputation updates", async function () {
      // Create listing
      const tx = await capoep.connect(user1).createListing(
        "Test Achievement",
        "Demonstrating skills",
        ["https://proof.com"],
        "Learning"
      );
      await tx.wait();

      console.log("Listing created");

      // Find the listing ID from the previous transaction
      const listingFilter = capoep.filters.ListingCreated();
      const listingEvents = await capoep.queryFilter(listingFilter);
      const listingId = listingEvents[0].args[0];

      console.log("Listing ID:", listingId);

      // Get initial reputation
      const initialReputation1 = await reputationModule.getReputation(user2.address);
      const initialReputation2 = await reputationModule.getReputation(user3.address);

      console.log("Initial Reputation Voter1:", initialReputation1);
      console.log("Initial Reputation Voter2:", initialReputation2);

      // Cast votes
      try {
        const voteTx1 = await capoep.connect(user2).castVote(
          listingId, 
          true, 
          "Positive vote"
        );
        await voteTx1.wait();

        const voteTx2 = await capoep.connect(user3).castVote(
          listingId, 
          true, 
          "Another positive vote"
        );
        await voteTx2.wait();
      } catch (error) {
        console.error("Vote casting error:", error);
        throw error;
      }

      console.log("Votes cast");

      // Check reputation after voting
      const finalReputation1 = await reputationModule.getReputation(user2.address);
      const finalReputation2 = await reputationModule.getReputation(user3.address);

      console.log("Final Reputation Voter1:", finalReputation1);
      console.log("Final Reputation Voter2:", finalReputation2);

      // Verify reputation increase
      expect(finalReputation1).to.be.gt(initialReputation1);
      expect(finalReputation2).to.be.gt(initialReputation2);
    });

    it("Should prevent voting with insufficient reputation", async function () {
      // Create listing
      await capoep.connect(user1).createListing(
        "Test Achievement",
        "Demonstrating skills",
        ["https://proof.com"],
        "Learning"
      );

      console.log("Listing created");

      // Find the listing ID from the previous transaction
      const listingFilter = capoep.filters.ListingCreated();
      const listingEvents = await capoep.queryFilter(listingFilter);
      const listingId = listingEvents[0].args[0];

      console.log("Listing ID:", listingId);

      // Create a new account with no reputation
      const [, , , , lowRepUser] = await ethers.getSigners();

      // Verify low reputation
      const lowReputation = await reputationModule.getReputation(lowRepUser.address);
      console.log("Low Reputation User Reputation:", lowReputation);
      expect(lowReputation).to.be.lte(0, "Low reputation user should have zero or negative reputation");

      // Attempt to cast vote with low reputation
      await expect(
        capoep.connect(lowRepUser).castVote(
          listingId, 
          true, 
          "Attempt to vote with low reputation"
        )
      ).to.be.revertedWithCustomError(capoep, "InsufficientReputation");
    });
  });
});
