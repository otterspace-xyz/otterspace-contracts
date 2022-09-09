import { NFTStorage, File } from 'nft.storage'
import fs from 'fs'
import { Contract, Signer } from 'ethers'

const { ethers } = require('hardhat')
const path = require('path')
const Raft = require('../artifacts/src/Raft.sol/Raft.json')

const API_KEY = process.env.NFT_STORAGE_API_KEY

// CAHNGE THESE VALUES //
const RAFT_ADDRESS_GOERLI = '0xBb8997048e5F0bFe6C9D6BEe63Ede53BD0236Bb2'
const RAFT_ADDRESS_OPTIMISM = '0xa6773847d3D2c8012C9cF62818b320eE278Ff722'

const daoName = 'georgeDAO'
const recipientAddress = '0x76D84163bc0BbF58d6d3F2332f8A9c5B339dF983'

async function storeAsset() {
  // @ts-ignore:next-line
  const client = new NFTStorage({ token: API_KEY })
  const raftPath = path.resolve(__dirname, '../../raft.gif')
  const metadata = await client.store({
    name: daoName,
    description: 'Otterspace Raft',
    properties: {
      parentRaftTokenId: null,
      generation: 0,
    },
    image: new File([await fs.promises.readFile(raftPath)], '../../raft.gif', {
      type: 'image/gif',
    }),
  })
  console.log('metadata url = ', `https://ipfs.io/ipfs/${metadata.ipnft}/metadata.json`)

  return `https://ipfs.io/ipfs/${metadata.ipnft}/metadata.json`
}

const mintRaft = async (url: any) => {
  const [owner] = await ethers.getSigners()
  let provider = ethers.getDefaultProvider()

  // @ts-ignore:next-line
  const contract = new Contract(RAFT_ADDRESS_GOERLI, Raft.abi, provider)
  const txn = await contract.connect(owner).mint(recipientAddress, url)
  await txn.wait()
  console.log('Minted raft with txn hash:', txn.hash)
}

storeAsset()
  //first argument is the recipient address
  // second argument is the DAO name
  .then(url => mintRaft(url))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
