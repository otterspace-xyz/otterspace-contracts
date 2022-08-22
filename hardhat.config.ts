import fs from 'fs'
import '@nomiclabs/hardhat-waffle'
import '@typechain/hardhat'
import 'hardhat-preprocessor'
import '@nomiclabs/hardhat-ethers'
import 'hardhat-watcher'
import '@openzeppelin/hardhat-upgrades'
import '@openzeppelin/hardhat-defender'
import '@nomiclabs/hardhat-etherscan'

import { HardhatUserConfig, task } from 'hardhat/config'

import example from './tasks/example'
require('dotenv').config()
const PRIVATE_KEY_1 = process.env.PRIVATE_KEY_1
// extra private keys only needed to run tests on live networks
// provide them in the "accounts" array below
// const PRIVATE_KEY_2 = process.env.PRIVATE_KEY_2
// const PRIVATE_KEY_3 = process.env.PRIVATE_KEY_3
// const PRIVATE_KEY_4 = process.env.PRIVATE_KEY_4
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY
const ETHERSCAN_API_KEY_GOERLI = process.env.ETHERSCAN_API_KEY_GOERLI
function getRemappings() {
  return fs
    .readFileSync('remappings.txt', 'utf8')
    .split('\n')
    .filter(Boolean)
    .map(line => line.trim().split('='))
}

task('example', 'Example task').setAction(example)

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
      url: `${process.env.ETH_GOERLI_URL}`,
      accounts: [`0x${PRIVATE_KEY_1}`],
      chainId: 5,
      timeout: 20000,
    },
    rinkeby: {
      url: `${process.env.ETH_RINKEBY_URL}`,
      accounts: [`0x${PRIVATE_KEY_1}`],
      chainId: 4,
      timeout: 20000,
    },
    optimisticEthereum: {
      url: `${process.env.OPTIMISM_URL}`,
      accounts: [`0x${PRIVATE_KEY_1}`],
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
      optimisticEthereum: ETHERSCAN_API_KEY!,
      goerli: ETHERSCAN_API_KEY_GOERLI!,
      rinkeby: ETHERSCAN_API_KEY_GOERLI!,
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
