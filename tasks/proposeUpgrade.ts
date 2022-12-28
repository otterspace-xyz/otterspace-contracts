import { HardhatRuntimeEnvironment } from 'hardhat/types/runtime'

require('@openzeppelin/hardhat-upgrades')
require('dotenv').config()

const addresses: { [key: string]: string } = {
  Badges: '0xa6773847d3D2c8012C9cF62818b320eE278Ff722',
  SpecDataHolder: '0x7F9279B24D1c36Fa3E517041fdb4E8788dc63D25',
  Raft: '0xBb8997048e5F0bFe6C9D6BEe63Ede53BD0236Bb2',
};

export default async function proposeUpgrade(params: any, hre: HardhatRuntimeEnvironment): Promise<void> {
    await hre.run('compile')
    console.log("hi ")
  // we'll call the script like node scripts/propose-upgrade.js Badges
  console.log("🚀 ~ proposeUpgrade ~ process.env.MULTISIG_GOERLI", process.env.MULTISIG_GOERLI)

  const contractName = process.argv[2]
  console.log('process.argv[1]', process.argv[1])
  console.log('process.argv[2]', process.argv[2])
    console.log('process.argv[3]', process.argv[3])
  const Implementation = await hre.ethers.getContractFactory(contractName)
  const proposal = await hre.defender.proposeUpgrade(
    addresses[contractName],
    Implementation, {
      title: `Upgrade ${contractName} implementation to ${Implementation}`,
      multisig: process.env.MULTISIG_GOERLI,
    }
  )
  console.log('🚀 ~ proposeUpgrade ~ proposal', proposal)
  console.log('Upgrade proposal created at:', proposal.url)
}
