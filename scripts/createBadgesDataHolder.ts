const { ethers, upgrades } = require('hardhat')

async function main() {
  const [deployer] = await ethers.getSigners()

  const raft = await ethers.getContractFactory('Raft')
  const raftContract = await raft.deploy()

  const badges = await ethers.getContractFactory('Badges')
  const badgesContract = await badges.deploy()

  const badgesDataHolder = await ethers.getContractFactory('BadgesDataHolder')
  const badgesDataHolderContract = await upgrades.deployProxy(badgesDataHolder, [
    raftContract.address,
    badgesContract.address,
  ])
  await badgesDataHolderContract.deployed()
}
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
