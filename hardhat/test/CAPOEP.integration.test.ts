import { expect } from "chai";
import { ethers } from "hardhat";
import { ContractTransactionResponse } from "ethers";
import { CAPOEP } from "../typechain-types/contracts/CAPOEP";
import { MetadataModule } from "../typechain-types/contracts/modules/MetadataModule";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("CAPOEP Integration", function () {
  let capoep: CAPOEP & {
    deploymentTransaction(): ContractTransactionResponse;
  };
  let metadata: MetadataModule & {
    deploymentTransaction(): ContractTransactionResponse;
  };
  let owner: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    // Deploy MetadataModule first
    const MetadataModule = await ethers.getContractFactory(
      "contracts/modules/MetadataModule.sol:MetadataModule",
    );
    metadata = (await MetadataModule.deploy()) as MetadataModule & {
      deploymentTransaction(): ContractTransactionResponse;
    };

    // Deploy CAPOEP with metadata address
    const CAPOEP = await ethers.getContractFactory(
      "contracts/CAPOEP.sol:CAPOEP",
    );
    capoep = (await CAPOEP.deploy(
      owner.address,
      await metadata.getAddress(),
    )) as CAPOEP & {
      deploymentTransaction(): ContractTransactionResponse;
    };
    await capoep.waitForDeployment();
  });

  describe("Listing Creation and Minting", function () {
    it("Should handle complete listing lifecycle", async function () {
      // Create listing
      await capoep
        .connect(user1)
        .createListing(
          "Learning Solidity",
          "Completed advanced Solidity course",
          ["https://proof1.com"],
          "Learning",
        );

      // Get attestations
      await capoep.connect(user2).castVote(0, true, "Great work!");
      await capoep.connect(owner).castVote(0, true, "Verified!");

      // Mint NFT
      await capoep.connect(user1).mintFromListing(0);

      // Verify NFT ownership
      expect(await capoep.ownerOf(0)).to.equal(user1.address);
    });
  });
});
