const { ethers, upgrades } = require('hardhat')

const proxyAddress = '0x3d24eC0BA04CEcA732a0F1AF6BC82481aFbD40c1'

async function main() {
  const contract = await ethers.getContractFactory('BadgesDataHolderV2')
  console.log('Upgrading...')
  const tx = await upgrades.upgradeProxy(proxyAddress, contract)
  console.log('upgraded successfully')
  console.log('tx = ', tx)
}

main()
