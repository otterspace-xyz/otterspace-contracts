import { HardhatRuntimeEnvironment } from 'hardhat/types/runtime'

require('@openzeppelin/hardhat-upgrades')
require('dotenv').config()

const addresses: { [key: string]: string } = {
  Badges: '0xa6773847d3D2c8012C9cF62818b320eE278Ff722',
  SpecDataHolder: '0x7F9279B24D1c36Fa3E517041fdb4E8788dc63D25',
  Raft: '0xBb8997048e5F0bFe6C9D6BEe63Ede53BD0236Bb2',
};

export default async function proposeUpgrade(params: any, hre: HardhatRuntimeEnvironment): Promise<void> {
    // await hre.run('compile')
  const contractName = process.argv[3]
    console.log('process.argv[3]', process.argv[3])
    // hre.upgrades.forceImport(addresses[contractName], 'Badges',)
  const Implementation = await hre.ethers.getContractFactory(contractName)
  const proposal = await hre.defender.proposeUpgrade(
    addresses[contractName],
    Implementation, {
    multisig: process.env.MULTISIG_GOERLI,
      title: `Upgrade ${contractName} implementation to ${Implementation}`,
    }
  )
  console.log('🚀 ~ proposeUpgrade ~ proposal', proposal)
  console.log('Upgrade proposal created at:', proposal.url)
}
