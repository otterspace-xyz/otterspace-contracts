import { HardhatRuntimeEnvironment } from 'hardhat/types/runtime'

require('@openzeppelin/hardhat-upgrades')
require('dotenv').config()

import raft from '../test/abis/latest/Raft.json'
const raftAbi = raft.abi
const raftBytecode = raft.bytecode

import specDataHolder from '../test/abis/latest/SpecDataHolder.json'
const specDataHolderAbi = specDataHolder.abi
const specDataHolderBytecode = specDataHolder.bytecode

import badges from '../test/abis/latest/Badges.json'
const badgesAbi = badges.abi
const badgesBytecode = badges.bytecode

export default async function testUpgrade(params: any, hre: HardhatRuntimeEnvironment): Promise<void> {
  const { BADGES_NAME: badgesName, BADGES_SYMBOL: badgesSymbol, BADGES_VERSION: badgesVersion } = process.env
  // runs npx hardhat compile
  await hre.run('compile')
  const ethers = hre.ethers
  const upgrades = hre.upgrades
  const [owner] = await ethers.getSigners()
  const raft = await ethers.getContractFactory(raftAbi, raftBytecode, owner)

  const raftProxy = await upgrades.deployProxy(raft, [owner.address, 'Raft', 'RAFT'], {
    kind: 'uups',
  })
  await raftProxy.deployed()

  const specDataHolder = await ethers.getContractFactory(specDataHolderAbi, specDataHolderBytecode, owner)
  const specDataHolderProxy = await upgrades.deployProxy(specDataHolder, [raftProxy.address, owner.address], {
    kind: 'uups',
  })
  await specDataHolderProxy.deployed()

  const badges = await ethers.getContractFactory(badgesAbi, badgesBytecode, owner)
  const badgesProxy = await upgrades.deployProxy(
    badges,
    [badgesName, badgesSymbol, badgesVersion, owner.address, specDataHolderProxy.address],
    {
      kind: 'uups',
    }
  )
  await badgesProxy.deployed()

  const badgesImplementation = await ethers.getContractFactory('Badges')
  const upgradedBadgesContract = await upgrades.upgradeProxy(badgesProxy.address, badgesImplementation)
  await upgradedBadgesContract.deployed()
  console.log('BADGES contract upgraded successfully')

  const raftImplementation = await ethers.getContractFactory('Raft')
  const upgradedRaftContract = await upgrades.upgradeProxy(raftProxy.address, raftImplementation)
  await upgradedRaftContract.deployed()
  console.log('RAFT contract upgraded successfully')

  const specDataHolderImplementation = await ethers.getContractFactory('SpecDataHolder')
  const upgradedspecDataHolderContract = await upgrades.upgradeProxy(
    specDataHolderProxy.address,
    specDataHolderImplementation
  )
  await upgradedspecDataHolderContract.deployed()
  console.log('SPECDATAHOLDER contract upgraded successfully')
}
