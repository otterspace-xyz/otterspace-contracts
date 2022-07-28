import { ethers, upgrades } from 'hardhat'

async function main() {
  const [deployer] = await ethers.getSigners()

  const raft = await ethers.getContractFactory('Raft')
  const raftContract = await raft.deploy(deployer.address, 'Otter', 'Ottr')

  const badgesDataHolder = await ethers.getContractFactory('BadgesDataHolder')
  const badgesDataHolderContract = await upgrades.deployProxy(badgesDataHolder, [
    raftContract.address,
    deployer.address,
  ])
  await badgesDataHolderContract.deployed()
  console.log('deployed to address = ', badgesDataHolderContract.address)
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
