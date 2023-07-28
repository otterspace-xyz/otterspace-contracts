const { AdminClient } = require('defender-admin-client')
require('dotenv').config()

const {
  GOERLI_BADGES_ADDRESS,
  GOERLI_RAFT_ADDRESS,
  GOERLI_SPECDATAHOLDER_ADDRESS,
  OPTIMISM_BADGES_ADDRESS,
  OPTIMISM_RAFT_ADDRESS,
  OPTIMISM_SPECDATAHOLDER_ADDRESS,
  OPTIMISM_GOERLI_BADGES_ADDRESS,
  OPTIMISM_GOERLI_RAFT_ADDRESS,
  OPTIMISM_GOERLI_SPECDATAHOLDER_ADDRESS,
  DEFENDER_TEAM_API_KEY,
  DEFENDER_TEAM_API_SECRET_KEY,
  GOERLI_GNOSIS_SAFE,
  OPTIMISM_GNOSIS_SAFE,
  MAINNET_GNOSIS_SAFE,
  MAINNET_BADGES_ADDRESS,
  MAINNET_RAFT_ADDRESS,
  MAINNET_SPECDATAHOLDER_ADDRESS,
  SEPOLIA_BADGES_ADDRESS,
  SEPOLIA_RAFT_ADDRESS,
  SEPOLIA_SPECDATAHOLDER_ADDRESS,  
} = process.env

async function createProposal() {
  try {
    const client = new AdminClient({
      apiKey: DEFENDER_TEAM_API_KEY,
      apiSecret: DEFENDER_TEAM_API_SECRET_KEY,
    })
    console.log('🚀 ~ createProposal ~ process.argv[2]', process.argv[2])
    console.log('🚀 ~ createProposal ~ process.argv[3]', process.argv[3])
    console.log('🚀 ~ createProposal ~ process.argv[4]', process.argv[4])
    
    const contract = {}
    const implementationAddress = process.argv[2]
    const contractName = process.argv[3]
    const network = process.argv[4]

    contract.name = contractName
    switch (contractName) {
      case 'badges':
        if (network === 'goerli') {
          contract.address = GOERLI_BADGES_ADDRESS
          contract.network = 'goerli'
        } else if (network === 'optimism') {
          contract.address = OPTIMISM_BADGES_ADDRESS
          contract.network = 'optimism'
        } else if (network === 'optimism-goerli') {
          contract.address = OPTIMISM_GOERLI_BADGES_ADDRESS
          contract.network = 'optimism-goerli'
        } else if (network === 'mainnet') {
          contract.address = MAINNET_BADGES_ADDRESS
          contract.network = 'mainnet'
        } else if (network === 'polygon') {
          contract.address = POLYGON_BADGES_ADDRESS
          contract.network = 'polygon'
        } else if (network === 'sepolia') {
          contract.address = SEPOLIA_BADGES_ADDRESS
          contract.network = 'sepolia'
        }
        break
      case 'raft':
        if (network === 'goerli') {
          contract.address = GOERLI_RAFT_ADDRESS
          contract.network = 'goerli'
        } else if (network === 'optimism') {
          contract.address = OPTIMISM_RAFT_ADDRESS
          contract.network = 'optimism'
        } else if (network === 'optimism-goerli') {
          contract.address = OPTIMISM_GOERLI_RAFT_ADDRESS
          contract.network = 'optimism-goerli'
        } else if (network === 'mainnet') {
          contract.address = MAINNET_RAFT_ADDRESS
          contract.network = 'mainnet'
        } else if (network === 'polygon') {
          contract.address = POLYGON_RAFT_ADDRESS
          contract.network = 'polygon'
        } else if (network === 'sepolia') {
          contract.address = SEPOLIA_RAFT_ADDRESS
          contract.network = 'sepolia'
        }
        break
      case 'specDataHolder':
        if (network === 'goerli') {
          contract.address = GOERLI_SPECDATAHOLDER_ADDRESS
          contract.network = 'goerli'
        } else if (network === 'optimism') {
          contract.address = OPTIMISM_SPECDATAHOLDER_ADDRESS
          contract.network = 'optimism'
        } else if (network === 'optimism-goerli') {
          contract.address = OPTIMISM_GOERLI_SPECDATAHOLDER_ADDRESS
          contract.network = 'optimism-goerli'
        } else if (network === 'mainnet') {
          contract.address = MAINNET_SPECDATAHOLDER_ADDRESS
          contract.network = 'mainnet'
        } else if (network === 'polygon') {
          contract.address = POLYGON_SPECDATAHOLDER_ADDRESS
          contract.network = 'polygon'
        } else if (network === 'sepolia') {
          contract.address = SEPOLIA_SPECDATAHOLDER_ADDRESS
          contract.network = 'sepolia'
        }
        break
      default:
        throw new Error('Invalid contract name')
    }

    let via
    let viaType
    const sharedWalletAddress = '0x21b02E9131D1BADE784a7874967DCb8Ef243F2A4'
    switch (network) {
      case 'goerli':
        via = GOERLI_GNOSIS_SAFE
        viaType = 'Gnosis Safe'
        break
      case 'optimism-goerli':
        // gnosis safe doesnt support optimism-goerli, so we need an address here
        via = sharedWalletAddress
        viaType = 'EOA'
        break
      case 'optimism':
        via = OPTIMISM_GNOSIS_SAFE
        viaType = 'Gnosis Safe'
        break
      case 'mainnet':
        via = MAINNET_GNOSIS_SAFE
        viaType = 'Gnosis Safe'
        break
      case 'sepolia':
        // gnosis safe doesnt support Sepolia, so we need an address here
        via = sharedWalletAddress
        viaType = 'EOA'
        break        
      default:
        throw new Error('Invalid network')
    }
    const upgradeParams = {
      title: `Upgrade ${contractName} to ${implementationAddress}`,
      description: `proposed automatically from github action`,
      via,
      viaType,
      newImplementation: implementationAddress,
    }
    
    await client.proposeUpgrade(upgradeParams, contract)
  } catch (error) {
    console.log('🚀 ~ createProposal ~ error:', error)
  }
}
createProposal()
