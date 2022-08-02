import fs from 'fs'
import '@nomiclabs/hardhat-waffle'
import '@typechain/hardhat'
import 'hardhat-preprocessor'
import '@nomiclabs/hardhat-ethers'
import 'hardhat-watcher'
import '@openzeppelin/hardhat-upgrades'
import '@openzeppelin/hardhat-defender'
import { HardhatUserConfig, task } from 'hardhat/config'

import example from './tasks/example'
require('dotenv').config()

function getRemappings() {
  return fs
    .readFileSync('remappings.txt', 'utf8')
    .split('\n')
    .filter(Boolean)
    .map(line => line.trim().split('='))
}

task('example', 'Example task').setAction(example)

const config: HardhatUserConfig = {
  // todo figure out TS issue for apiKey and apiSecret
  defender: {
    apiKey: process.env.DEFENDER_TEAM_API_KEY!,
    apiSecret: process.env.DEFENDER_TEAM_API_SECRET_KEY!,
  },
  solidity: {
    version: '0.8.15',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    optimismGoerli: {
      url: `${process.env.OPTIMISM_GOERLI_URL}`,
      accounts: [process.env.PRIVATE_KEY!],
    },
    goerli: {
      url: `${process.env.ETH_GOERLI_URL}`,
      accounts: [process.env.PRIVATE_KEY!],
    },
    rinkeby: {
      url: `${process.env.RINKEBY_URL}`,
      accounts: [process.env.PRIVATE_KEY!],
    },
  },
  paths: {
    sources: './src', // Use ./src rather than ./contracts as Hardhat expects
    cache: './cache_hardhat', // Use a different cache for Hardhat than Foundry
  },
  watcher: {
    test: {
      tasks: [{ command: 'test', params: { testFiles: ['{path}'] } }],
      files: ['./test/**/*'],
      verbose: true,
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
