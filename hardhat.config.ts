import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";

dotenv.config();
const optimizerEnabled = !process.env.OPTIMIZER_DISABLED;
const privateKey = process.env.PRIVATE_KEY;
const etherscanAPIKey = process.env.ETHERSCAN_API_KEY;
const ropstenURL = process.env.ROPSTEN_URL;

const { MUMBAI_API_URL } = process.env;
// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.6",
        settings: {
          optimizer: {
            enabled: optimizerEnabled,
            runs: 2000,
          },
          evmVersion: "berlin",
        },
      },
    ],
  },
  networks: {
    hardhat: {},
    ropsten: {
      url: ropstenURL || "",
      accounts: privateKey !== undefined ? [privateKey] : [],
    },
    polygon_mumbai: {
      url: MUMBAI_API_URL,
      accounts: privateKey !== undefined ? [`0x${privateKey}`] : []
   }    
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: etherscanAPIKey,
  },
};

export default config;
