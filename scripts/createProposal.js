const request = require('request')
const defenderAdminClient = require('defender-admin-client')

const TEAM_API_KEY = process.env.DEFENDER_TEAM_API_KEY
const TEAM_API_SECRET_KEY = process.env.DEFENDER_TEAM_API_SECRET_KEY

async function createProposal(implementation) {
  const bearerToken = await defenderAdminClient.getBearerToken(
    TEAM_API_KEY,
    TEAM_API_SECRET_KEY
  )

  const options = {
    method: 'POST',
    url: 'https://api.defender.dev/proposals',
    headers: {
      Authorization: `Bearer ${bearerToken}`,
      'Content-Type': 'application/json',
    },
    body: {
      contract: {
        network: 'goerli',
        address: '0x7F9279B24D1c36Fa3E517041fdb4E8788dc63D25',
        name: 'Badges',
      },
      title: 'Upgrade to New Implementation',
      description:
        'This proposal will upgrade MyContract to a new implementation contract.',
      type: 'upgrade',
      metadata: {
        newImplementationAddress: implementation,
      },
    },
  }
}

export default createProposal
