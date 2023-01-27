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
  console.log('🚀 ~ createProposal ~ contract', contract)
  const via = network === 'goerli' ? GOERLI_GNOSIS_SAFE : OPTIMISM_GNOSIS_SAFE
  console.log('🚀 ~ createProposal ~ via', via)
  const viaType = 'Gnosis Safe'
  client.proposeUpgrade({ newImplementation, via, viaType }, contract)
}
createProposal()
