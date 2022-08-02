const { ethers, upgrades } = require('hardhat')

async function main() {
  // TODO: replace with an environment variable
  const ownerAddress = '0xbC12E44052fddf5789833BD9096a9c4906D8fbb0'
  const [deployer] = await ethers.getSigners()

  const raft = await ethers.getContractFactory('Raft')
  const raftContract = await upgrades.deployProxy(raft, [ownerAddress, 'Raft', 'RAFT'], {
    kind: 'uups',
  })
  await raftContract.deployed()

  console.log('raft contract deployed to address = ', raftContract.address)

  const specDataHolder = await ethers.getContractFactory('SpecDataHolder')
  const specDataHolderContract = await upgrades.deployProxy(specDataHolder, [raftContract.address, ownerAddress], {
    kind: 'uups',
  })
  await specDataHolderContract.deployed()

  console.log('specDataHolder deployed to address = ', specDataHolderContract.address)

  const badges = await ethers.getContractFactory('Badges')
  const badgesContract = await upgrades.deployProxy(
    badges,
    ['Badges', 'BAD', '1.0.0', ownerAddress, specDataHolderContract.address],
    {
      kind: 'uups',
    }
  )
  await badgesContract.deployed()
  console.log('badges contract deployed to address = ', badgesContract.address)
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
