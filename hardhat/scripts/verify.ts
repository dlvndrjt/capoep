import { run } from "hardhat";

async function main() {
  const METADATA_ADDRESS = process.env.METADATA_ADDRESS;
  const REPUTATION_ADDRESS = process.env.REPUTATION_ADDRESS;
  const CAPOEP_ADDRESS = process.env.CAPOEP_ADDRESS;
  const DEPLOYER_ADDRESS = process.env.DEPLOYER_ADDRESS;

  if (!METADATA_ADDRESS || !REPUTATION_ADDRESS || !CAPOEP_ADDRESS || !DEPLOYER_ADDRESS) {
    throw new Error("Missing required environment variables");
  }

  console.log("Verifying contracts...");

  // Verify MetadataModule
  console.log("\nVerifying MetadataModule...");
  try {
    await run("verify:verify", {
      address: METADATA_ADDRESS,
      constructorArguments: [],
    });
    console.log("MetadataModule verified successfully");
  } catch (error) {
    console.error("Error verifying MetadataModule:", error);
  }

  // Verify ReputationModule
  console.log("\nVerifying ReputationModule...");
  try {
    await run("verify:verify", {
      address: REPUTATION_ADDRESS,
      constructorArguments: [DEPLOYER_ADDRESS],
    });
    console.log("ReputationModule verified successfully");
  } catch (error) {
    console.error("Error verifying ReputationModule:", error);
  }

  // Verify CAPOEP
  console.log("\nVerifying CAPOEP...");
  try {
    await run("verify:verify", {
      address: CAPOEP_ADDRESS,
      constructorArguments: [
        DEPLOYER_ADDRESS,
        METADATA_ADDRESS,
        REPUTATION_ADDRESS,
      ],
    });
    console.log("CAPOEP verified successfully");
  } catch (error) {
    console.error("Error verifying CAPOEP:", error);
  }

  console.log("\nVerification complete!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
