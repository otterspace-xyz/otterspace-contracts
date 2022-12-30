import fs from 'fs'
import '@nomiclabs/hardhat-waffle'
import '@typechain/hardhat'
import 'hardhat-preprocessor'
import '@nomiclabs/hardhat-ethers'
import 'hardhat-watcher'
import '@openzeppelin/hardhat-upgrades'
import '@openzeppelin/hardhat-defender'
import '@nomiclabs/hardhat-etherscan'
import { HardhatRuntimeEnvironment } from 'hardhat/types/runtime'

import { HardhatUserConfig, task } from 'hardhat/config'

import testUpgrade from './tasks/testUpgrade'




require('dotenv').config()

const DEPLOYER_PRIVATE_KEY = process.env.DEPLOYER_PRIVATE_KEY
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY
const OPTIMISTIC_ETHERSCAN_API_KEY = process.env.OPTIMISTIC_ETHERSCAN_API_KEY

function getRemappings() {
  return fs
    .readFileSync('remappings.txt', 'utf8')
    .split('\n')
    .filter(Boolean)
    .map(line => line.trim().split('='))
}

task('testUpgrade', 'Example task').setAction(testUpgrade)


const config: HardhatUserConfig = {
  defender: {
    apiKey: process.env.DEFENDER_TEAM_API_KEY!,
    apiSecret: process.env.DEFENDER_TEAM_API_SECRET_KEY!,
  },
  solidity: {
    version: '0.8.16',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    goerli: {
      url: `${process.env.GOERLI_RPC_URL}`,
      accounts: [`0x${DEPLOYER_PRIVATE_KEY}`],
      chainId: 5,
      timeout: 20000,
    },
    optimisticEthereum: {
      url: `${process.env.OPTIMISM_RPC_URL}`,
      accounts: [`0x${DEPLOYER_PRIVATE_KEY}`],
      chainId: 10,
      timeout: 20000,
    },
  },
  paths: {
    sources: './src', // Use ./src rather than ./contracts as Hardhat expects
    cache: './cache_hardhat', // Use a different cache for Hardhat than Foundry
  },
  // if a test takes longer than 40s Hardhat will fail it
  mocha: {
    timeout: 100000000,
  },
  watcher: {
    test: {
      tasks: [{ command: 'test', params: { testFiles: ['{path}'] } }],
      files: ['./test/**/*'],
      verbose: true,
    },
  },
  etherscan: {
    apiKey: {
      optimisticEthereum: OPTIMISTIC_ETHERSCAN_API_KEY!,
      goerli: ETHERSCAN_API_KEY!,
    },
  },
  // This fully resolves paths for imports in the ./lib directory for Hardhat
  preprocess: {
    eachLine: hre => ({
      transform: (line: string) => {
        if (line.match(/^\s*import /i)) {
          getRemappings().forEach(([find, replace]) => {
            if (line.match(find)) {
              line = line.replace(find, replace)
            }
          })
        }
        return line
      },
    }),
  },
}

export default config
