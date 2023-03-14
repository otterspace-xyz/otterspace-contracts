const { AdminClient } = require('defender-admin-client')
require('dotenv').config()

const {
  GOERLI_BADGES_ADDRESS,
  GOERLI_RAFT_ADDRESS,
  GOERLI_SPECDATAHOLDER_ADDRESS,
  OPTIMISM_BADGES_ADDRESS,
  OPTIMISM_RAFT_ADDRESS,
  OPTIMISM_SPECDATAHOLDER_ADDRESS,
  DEFENDER_TEAM_API_KEY,
  DEFENDER_TEAM_API_SECRET_KEY,
  GOERLI_GNOSIS_SAFE,
  OPTIMISM_GNOSIS_SAFE,
} = process.env

async function createProposal() {
  const client = new AdminClient({
    apiKey: DEFENDER_TEAM_API_KEY,
    apiSecret: DEFENDER_TEAM_API_SECRET_KEY,
  })
  const newImplementation = process.argv[2]
  console.log('🚀 ~ createProposal ~ process.argv[0]', process.argv[0])
  console.log('🚀 ~ createProposal ~ process.argv[1]', process.argv[1])
  console.log('🚀 ~ createProposal ~ process.argv[2]', process.argv[2])
  console.log('🚀 ~ createProposal ~ process.argv[3]', process.argv[3])
  console.log('🚀 ~ createProposal ~ newImplementation', newImplementation)

  const contract = {}
  const contractName = process.argv[3]
  const network = process.argv[4]

  switch (contractName) {
    case 'badges':
      if (network === 'goerli') {
        contract.address = GOERLI_BADGES_ADDRESS
        contract.network = 'goerli'
      } else if (network === 'optimism') {
        contract.address = OPTIMISM_BADGES_ADDRESS
        contract.network = 'optimism'
      }
      break
    case 'raft':
      if (network === 'goerli') {
        contract.address = GOERLI_RAFT_ADDRESS
        contract.network = 'goerli'
      } else if (network === 'optimism') {
        contract.address = OPTIMISM_RAFT_ADDRESS
        contract.network = 'optimism'
      }
      break
    case 'specDataHolder':
      if (network === 'goerli') {
        contract.address = GOERLI_SPECDATAHOLDER_ADDRESS
        contract.network = 'goerli'
      } else if (network === 'optimism') {
        contract.address = OPTIMISM_SPECDATAHOLDER_ADDRESS
        contract.network = 'optimism'
      }
      break
  }

  let via

  switch (network) {
    case 'goerli':
      via = GOERLI_GNOSIS_SAFE
      break
    case 'optimism-goerli':
      via = GOERLI_GNOSIS_SAFE
      break
    case 'optimism':
      via = OPTIMISM_GNOSIS_SAFE
      break
    default:
      throw new Error('Invalid network')
  }
  console.log('🚀 ~ createProposal ~ contract', contract)

  console.log('🚀 ~ createProposal ~ via', via)
  const viaType = 'Gnosis Safe'
  client.proposeUpgrade({ newImplementation, via, viaType }, contract)
}
createProposal()
