import { expect } from "chai";
import { ethers } from "hardhat";
import { MetadataModule } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("MetadataModule", function () {
  let metadataModule: MetadataModule;
  let owner: SignerWithAddress;
  let user1: SignerWithAddress;

  beforeEach(async function () {
    [owner, user1] = await ethers.getSigners();
    const MetadataModule = await ethers.getContractFactory("MetadataModule");
    metadataModule = await MetadataModule.deploy();
    await metadataModule.waitForDeployment();
  });

  describe("Metadata Generation", function () {
    it("Should generate valid token URI", async function () {
      const tokenURI = await metadataModule.generateTokenURI(1);
      expect(tokenURI).to.include("data:application/json;base64,");

      const base64Json = tokenURI.split(",")[1];
      const jsonString = Buffer.from(base64Json, "base64").toString();
      console.log("JSON String length:", jsonString.length);
      console.log("Last 10 characters:", jsonString.slice(-10));

      // Try cleaning the string before parsing
      const cleanJsonString = jsonString.replace(/\0/g, "");
      const metadata = JSON.parse(cleanJsonString);

      expect(metadata).to.have.property("name");
      expect(metadata).to.have.property("description");
      expect(metadata).to.have.property("image");
      expect(metadata).to.have.property("attributes");
    });

    it("Should generate valid SVG", async function () {
      const svg = await metadataModule.generateSVG(1);
      expect(svg).to.include("<svg");
      expect(svg).to.include("</svg>");
      expect(svg).to.include("CAPOEP #1");
    });
  });

  describe("Attributes", function () {
    it("Should return correct attributes", async function () {
      const attributes = await metadataModule.getAttributes();
      expect(attributes).to.have.length(3);
      expect(attributes[0].traitType).to.equal("Type");
      expect(attributes[0].value).to.equal("Education");
    });
  });
});
