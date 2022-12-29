const { AdminClient } = require('defender-admin-client')

const apiKey = process.env.DEFENDER_TEAM_API_KEY
const apiSecret = process.env.DEFENDER_TEAM_API_SECRET_KEY
async function createProposal() {
  const client = new AdminClient({
    apiKey,
    apiSecret,
  })
  console.log('🚀 ~ apiKey', apiKey)
  console.log('🚀 ~ apiSecret', apiSecret)
  const newImplementation = process.argv[2]
  console.log('🚀 ~ createProposal ~ newImplementation', newImplementation)
  // const newImplementationAbi = '[...]'
  const contract = {
    network: 'goerli',
    address: newImplementation,
  }
  const res = await client.proposeUpgrade({ newImplementation }, contract)
  console.log('🚀 ~ createProposal ~ res', res)
}
createProposal()
