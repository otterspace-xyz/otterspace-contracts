const { ethers, upgrades } = require('hardhat')

const proxyAddress = '0x99e722b2CeA3e14f634EA7DBa755f3e5592FaE85'

async function main() {
  const contract = await ethers.getContractFactory('RaftV2')
  console.log('Upgrading...')
  const tx = await upgrades.upgradeProxy(proxyAddress, contract)
  console.log('upgraded successfully')
  console.log('tx = ', tx)
}

main()
