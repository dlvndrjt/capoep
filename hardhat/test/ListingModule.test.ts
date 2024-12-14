import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract } from "ethers";
import { deployContracts } from "./helpers";
import {
  ListingModule,
  VotingModule,
  CommentsModule,
  ReputationModule,
  CAPOEP,
} from "../typechain-types";

describe("ListingModule", function () {
  let listingModule: ListingModule;
  let votingModule: VotingModule;
  let commentsModule: CommentsModule;
  let reputationModule: ReputationModule;
  let capoep: CAPOEP;
  let owner: any;
  let user1: any;
  let user2: any;

  beforeEach(async function () {
    const [owner, user1, user2] = await ethers.getSigners();

    // Deploy CAPOEP and modules
    const ReputationModule =
      await ethers.getContractFactory("ReputationModule");
    reputationModule = await ReputationModule.deploy(owner.address);

    const ListingModule = await ethers.getContractFactory("ListingModule");
    listingModule = await ListingModule.deploy(owner.address, owner.address); // Temporary addresses

    const VotingModule = await ethers.getContractFactory("VotingModule");
    votingModule = await VotingModule.deploy(
      listingModule.address,
      commentsModule.address,
      reputationModule.address,
    );

    const CommentsModule = await ethers.getContractFactory("CommentsModule");
    commentsModule = await CommentsModule.deploy(
      owner.address,
      reputationModule.address,
      votingModule.address,
    );

    // Update module addresses
    await listingModule.updateVotingModule(votingModule.address);
  });

  describe("Listing Creation", function () {
    it("Should create a new listing", async function () {
      const title = "Learning Solidity";
      const details = "Completed a course";
      const proofs = ["ipfs://proof1", "https://example.com/cert"];
      const category = "learning";

      await expect(
        listingModule
          .connect(user1)
          .createListing(title, details, proofs, category),
      )
        .to.emit(listingModule, "ListingCreated")
        .withArgs(0, user1.address);

      const listing = await listingModule.getListing(0);
      expect(listing.title).to.equal(title);
      expect(listing.creator).to.equal(user1.address);
    });

    it("Should prevent duplicate listings", async function () {
      const title = "Learning Solidity";
      const details = "Completed a course";
      const proofs = ["ipfs://proof1"];
      const category = "learning";

      await listingModule
        .connect(user1)
        .createListing(title, details, proofs, category);

      await expect(
        listingModule
          .connect(user1)
          .createListing(title, details, proofs, category),
      ).to.be.revertedWithCustomError(listingModule, "ListingAlreadyExists");
    });
  });

  // Add more test cases...
});
