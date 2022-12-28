// scripts/propose-upgrade.js
const { defender, ethers } = require('hardhat')

const addresses = {
  Badges: '0xa6773847d3D2c8012C9cF62818b320eE278Ff722',
  SpecDataHolder: '0x7F9279B24D1c36Fa3E517041fdb4E8788dc63D25',
  Raft: '0xBb8997048e5F0bFe6C9D6BEe63Ede53BD0236Bb2',
}

async function main() {
  // we'll call the script like node scripts/propose-upgrade.js Badges
  const contractName = process.argv[2]
  console.log('🚀 ~ main ~ contractName', contractName)

  const Implementation = await ethers.getContractFactory(contractName)
  const proposal = await defender.proposeUpgrade(
    addresses[contractName],
    Implementation
  )
  console.log('🚀 ~ main ~ proposal', proposal)
  console.log('Upgrade proposal created at:', proposal.url)
}

main()
