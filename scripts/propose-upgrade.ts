// scripts/propose-upgrade.js
const { ethers, defender } = require('hardhat')

async function main() {
  const proxyAddress = '0x99e722b2CeA3e14f634EA7DBa755f3e5592FaE85'
  const gnosisSafeAddress = '0xbC12E44052fddf5789833BD9096a9c4906D8fbb0'

  const RaftV2 = await ethers.getContractFactory('RaftV2')
  console.log('Preparing proposal...')
  const proposal = await defender.proposeUpgrade(proxyAddress, RaftV2, {
    title: 'RaftV2',
    description: 'RaftV2',
    multisig: gnosisSafeAddress,
  })
  console.log('Upgrade proposal created at:', proposal.url)
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
