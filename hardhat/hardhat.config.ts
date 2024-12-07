import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

// const config: HardhatUserConfig = {
//   solidity: "0.8.27",
// };

// export default config;

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.27", // Keep your original version or update it if needed
    settings: {
      viaIR: false,
      optimizer: {
        enabled: true, // Enable the optimizer
        runs: 200, // This specifies the optimization level. You can set this based on your needs (default is 200)
      },
    },
  },
};

export default config;
