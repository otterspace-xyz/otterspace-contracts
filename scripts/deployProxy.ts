const { ethers, upgrades } = require('hardhat')
require('dotenv').config()

async function main() {
  const { BADGES_NAME, BADGES_SYMBOL, BADGES_VERSION, RAFT_NAME, RAFT_SYMBOL } = process.env

  const [deployer] = await ethers.getSigners()
  console.log('🚀 ~ main ~ deployer', deployer.address)

  const raft = await ethers.getContractFactory('Raft')
  const raftContract = await upgrades.deployProxy(raft, [deployer.address, RAFT_NAME, RAFT_SYMBOL], {
    kind: 'uups',
  })
  await raftContract.deployed()

  console.log('raft contract deployed to address = ', raftContract.address)

  const specDataHolder = await ethers.getContractFactory('SpecDataHolder')
  const specDataHolderContract = await upgrades.deployProxy(specDataHolder, [raftContract.address, deployer.address], {
    kind: 'uups',
  })
  await specDataHolderContract.deployed()

  console.log('specDataHolder deployed to address = ', specDataHolderContract.address)

  const badges = await ethers.getContractFactory('Badges')
  const badgesContract = await upgrades.deployProxy(
    badges,
    [BADGES_NAME, BADGES_SYMBOL, BADGES_VERSION, deployer.address, specDataHolderContract.address],
    {
      kind: 'uups',
    }
  )
  await badgesContract.deployed()
  console.log('badges contract deployed to address = ', badgesContract.address)
  console.log("All contracts are deployed. Next, go verify them! Here's the code to do that")
  console.log('npx hardhat verify --network ${networkName} ${contractAddress}')
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
