import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy MetadataModule
  console.log("Deploying MetadataModule...");
  const MetadataModule = await ethers.getContractFactory("MetadataModule");
  const metadata = await MetadataModule.deploy();
  await metadata.waitForDeployment();
  console.log("MetadataModule deployed to:", await metadata.getAddress());

  // Deploy ReputationModule
  console.log("Deploying ReputationModule...");
  const ReputationModule = await ethers.getContractFactory("ReputationModule");
  const reputation = await ReputationModule.deploy(deployer.address);
  await reputation.waitForDeployment();
  console.log("ReputationModule deployed to:", await reputation.getAddress());

  // Deploy CAPOEP
  console.log("Deploying CAPOEP...");
  const CAPOEP = await ethers.getContractFactory("CAPOEP");
  const capoep = await CAPOEP.deploy(
    deployer.address,
    await metadata.getAddress(),
    await reputation.getAddress()
  );
  await capoep.waitForDeployment();
  console.log("CAPOEP deployed to:", await capoep.getAddress());

  // Setup authorized updaters
  console.log("Setting up authorized updaters...");
  await reputation.addAuthorizedUpdater(await capoep.getAddress());
  console.log("CAPOEP authorized as reputation updater");

  console.log("\nDeployment complete!");
  console.log("--------------------");
  console.log("Contracts deployed:");
  console.log("- MetadataModule:", await metadata.getAddress());
  console.log("- ReputationModule:", await reputation.getAddress());
  console.log("- CAPOEP:", await capoep.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
