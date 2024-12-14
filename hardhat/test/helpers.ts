import { ethers } from "hardhat";
import { Contract } from "ethers";
import {
  CAPOEP,
  ListingModule,
  VotingModule,
  CommentsModule,
  ReputationModule,
  MetadataModule,
} from "../typechain-types";

export const SAMPLE_LISTING = {
  title: "Test Achievement",
  details: "This is a test achievement with details",
  proofs: ["https://example.com/proof1", "https://example.com/proof2"],
  category: "Test Category",
};

interface DeployedContracts {
  capoep: CAPOEP;
  listingModule: ListingModule;
  votingModule: VotingModule;
  commentsModule: CommentsModule;
  reputationModule: ReputationModule;
  metadataModule: MetadataModule;
  owner: any;
  user1: any;
  user2: any;
}

export async function deployContracts(): Promise<DeployedContracts> {
  const [owner, user1, user2] = await ethers.getSigners();

  // Deploy CAPOEP first
  const CAPOEP = await ethers.getContractFactory("CAPOEP");
  const capoep = await CAPOEP.deploy(owner.address);
  await capoep.waitForDeployment();

  // Deploy modules with proper initialization
  const ListingModule = await ethers.getContractFactory("ListingModule");
  const listingModule = await ListingModule.deploy(
    capoep.address,
    owner.address,
  );

  const MetadataModule = await ethers.getContractFactory("MetadataModule");
  const metadataModule = await MetadataModule.deploy(listingModule.address);

  const ReputationModule = await ethers.getContractFactory("ReputationModule");
  const reputationModule = await ReputationModule.deploy(owner.address);

  const VotingModule = await ethers.getContractFactory("VotingModule");
  const votingModule = await VotingModule.deploy(
    listingModule.address,
    commentsModule.address,
    reputationModule.address,
  );

  const CommentsModule = await ethers.getContractFactory("CommentsModule");
  const commentsModule = await CommentsModule.deploy(
    capoep.address,
    reputationModule.address,
    votingModule.address,
  );

  // Initialize modules
  await capoep.updateModules(
    listingModule.address,
    metadataModule.address,
    votingModule.address,
    commentsModule.address,
    reputationModule.address,
  );

  return {
    capoep,
    listingModule,
    votingModule,
    commentsModule,
    reputationModule,
    metadataModule,
    owner,
    user1,
    user2,
  };
}
