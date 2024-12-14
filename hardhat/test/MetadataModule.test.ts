import { expect } from "chai";
import { deployContracts, SAMPLE_LISTING } from "./helpers";
import { MetadataModule, ListingModule } from "../typechain-types";
import { ethers } from "hardhat";
import { Contract } from "ethers";

describe("MetadataModule", function () {
  let metadataModule: MetadataModule;
  let listingModule: ListingModule;
  let owner: SignerWithAddress;
  let user1: SignerWithAddress;
  let tokenId: number;

  beforeEach(async function () {
    const contracts = await deployContracts();
    metadataModule = contracts.metadataModule;
    listingModule = contracts.listingModule;
    owner = contracts.owner;
    user1 = contracts.user1;

    // Create a listing for testing
    await listingModule
      .connect(user1)
      .createListing(
        SAMPLE_LISTING.title,
        SAMPLE_LISTING.details,
        SAMPLE_LISTING.proofs,
        SAMPLE_LISTING.category,
      );
    tokenId = 0;
  });

  describe("Token URI Generation", function () {
    it("Should generate valid token URI", async function () {
      const tokenURI = await metadataModule.generateTokenURI(tokenId);
      expect(tokenURI).to.include("data:application/json;base64,");

      // Decode and parse the base64 JSON
      const json = Buffer.from(tokenURI.split(",")[1], "base64").toString();
      const metadata = JSON.parse(json);

      expect(metadata.name).to.equal(`CAPOEP #${tokenId}`);
      expect(metadata.description).to.include("Community Attested");
      expect(metadata.image).to.include("data:image/svg+xml;base64,");
      expect(metadata.attributes).to.be.an("array");
    });

    it("Should include correct attributes", async function () {
      const attributes = await metadataModule.getAttributes(tokenId);
      expect(attributes).to.have.lengthOf(5); // Category, Title, Creator, Attestations, Status

      const [category, title, creator, attestations, status] = attributes;
      expect(category.traitType).to.equal("Category");
      expect(category.value).to.equal(SAMPLE_LISTING.category);
      expect(title.traitType).to.equal("Title");
      expect(title.value).to.equal(SAMPLE_LISTING.title);
    });
  });

  describe("SVG Generation", function () {
    it("Should generate valid SVG", async function () {
      const svg = await metadataModule.generateSVG(tokenId);
      expect(svg).to.include("<svg");
      expect(svg).to.include("</svg>");
      expect(svg).to.include(`CAPOEP #${tokenId}`);
      expect(svg).to.include(SAMPLE_LISTING.title);
    });
  });
});
