import { expect } from 'chai'
import { ethers, upgrades } from 'hardhat'
import { Badges } from '../typechain-types'
import { BigNumberish } from 'ethers'
import type { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { waffle } from 'hardhat'
import {
  LogDescription,
  splitSignature,
  _TypedDataEncoder,
} from 'ethers/lib/utils'
import { MerkleTree } from 'merkletreejs'
import keccak256 from 'keccak256'

const name = 'Otter'
const symbol = 'OTTR'
const version = '1'
// ideally chainId would be dynamic depending upon if you're running tests locally or on a
//live network and automaticall set the chainId to the correct value.
const chainId = 31337
const specUri = 'some spec uri'
const specUri2 = 'another spec uri'
// ** CONTRACT ERRORS **
const errNotOwner = 'Ownable: caller is not the owner'
const errTokenExists = 'mint: tokenID exists'
const errSafeCheckMerkleInvalidSig =
  'safeCheckMerkleAgreement: invalid signature'

let deployed: any

// fix ts badgesProxy: any
async function createSpec(
  badgesProxy: any,
  specUri: string,
  raftTokenId: BigNumberish,
  signer: SignerWithAddress
) {
  const txn = await badgesProxy.connect(signer).createSpec(specUri, raftTokenId)
  const txReceipt = await txn.wait()
  expect(txReceipt.status).equal(1)
  return await getSpecCreatedEventLogData(txn.hash, badgesProxy)
}

async function mintRaftToken(
  raftProxy: any,
  toAddress: string,
  raftTokenUri: string,
  signer: SignerWithAddress
) {
  const txn = await raftProxy.connect(signer).mint(toAddress, raftTokenUri)
  const txReceipt = await txn.wait()
  expect(txReceipt.status).equal(1)

  const [transferEvent] = txReceipt.events!
  const { tokenId: rawTokenId } = transferEvent.args!
  const raftTokenId = ethers.BigNumber.from(rawTokenId).toNumber()
  expect(raftTokenId).gt(0)

  const raftTokenOwner = await raftProxy.ownerOf(raftTokenId)
  expect(raftTokenOwner).equal(toAddress)

  return { raftTokenOwner, raftTokenId }
}

async function getSignature(
  domain: any,
  types: any,
  value: any,
  signer: SignerWithAddress
) {
  const signature = await signer._signTypedData(domain, types, value)
  const { compact } = splitSignature(signature)
  return { compact }
}

enum EventType {
  Badges_BadgeMinted = 'BadgeMinted',
  Badges_SpecCreated = 'SpecCreated',
  ERC4973_Transfer = 'Transfer',
}

async function getParsedLogs(txnHash: string, badgesProxy: any) {
  const txnReceipt = await waffle.provider.getTransactionReceipt(txnHash)

  let parsedLogs: LogDescription[] = []
  txnReceipt.logs.forEach(log => {
    parsedLogs.push(badgesProxy.interface.parseLog(log))
  })

  return parsedLogs
}

async function getTransferEventLogData(txnHash: string, badgesProxy: any) {
  const parsedLogs = await getParsedLogs(txnHash, badgesProxy)
  const transferLog = parsedLogs.find(l => l.name == EventType.ERC4973_Transfer)

  const from = transferLog?.args['from']
  const to = transferLog?.args['to']
  const tokenId = transferLog?.args['tokenId'] as BigNumberish

  return { from, to, tokenId }
}

async function getSpecCreatedEventLogData(
  txnHash: string,
  badgesProxy: Badges
) {
  const parsedLogs = await getParsedLogs(txnHash, badgesProxy)
  const transferLog = parsedLogs.find(
    l => l.name == EventType.Badges_SpecCreated
  )

  const to = transferLog?.args['to']
  const specUri = transferLog?.args['specUri']
  const raftTokenId = transferLog?.args['raftTokenId'] as BigNumberish
  const raftAddress = transferLog?.args['raftAddress']

  return { to, specUri, raftTokenId, raftAddress }
}

const setup = async () => {
  await deployContractFixture()
}

beforeEach(setup)

const deployContractFixture = async () => {
  const [owner, issuer, claimant, randomSigner, merkleIssuer] =
    await ethers.getSigners()

  const raft = await ethers.getContractFactory('Raft')
  const raftProxy = await upgrades.deployProxy(
    raft,
    [owner.address, 'Raft', 'RAFT'],
    {
      kind: 'uups',
    }
  )

  await raftProxy.deployed()

  const specDataHolder = await ethers.getContractFactory('SpecDataHolder')
  const specDataHolderProxy = await upgrades.deployProxy(
    specDataHolder,
    [raftProxy.address, owner.address],
    {
      kind: 'uups',
    }
  )

  const raftAddress = await specDataHolderProxy.getRaftAddress()

  expect(raftAddress).equal(raftProxy.address)

  const badges = await ethers.getContractFactory('Badges')
  const badgesProxy = await upgrades.deployProxy(
    badges,
    [name, symbol, version, owner.address, specDataHolderProxy.address],
    { kind: 'uups' }
  )

  await specDataHolderProxy.setBadgesAddress(badgesProxy.address)

  const typedData = {
    domain: {
      name: name,
      version: version,
      chainId,
      verifyingContract: badgesProxy.address,
    },
    types: {
      Agreement: [
        { name: 'active', type: 'address' },
        { name: 'passive', type: 'address' },
        { name: 'tokenURI', type: 'string' },
      ],
    },
    value: {
      active: claimant.address,
      passive: issuer.address,
      tokenURI: specUri,
    },
  }

  const merkleTypedData = {
    domain: {
      name: name,
      version: version,
      chainId,
      verifyingContract: badgesProxy.address,
    },
    types: {
      MerkleAgreement: [
        { name: 'passive', type: 'address' },
        { name: 'tokenURI', type: 'string' },
        { name: 'root', type: 'bytes32' },
      ],
    },
    value: {
      passive: issuer.address,
      tokenURI: specUri,
      root: '',
    },
  }

  const requestTypedData = {
    domain: {
      name: name,
      version: version,
      chainId,
      verifyingContract: badgesProxy.address,
    },
    types: {
      Request: [
        { name: 'requester', type: 'address' },
        { name: 'tokenURI', type: 'string' },
      ],
    },
    value: {
      requester: claimant.address,
      tokenURI: specUri,
    },
  }

  deployed = {
    badgesProxy,
    raftProxy,
    owner,
    issuer,
    claimant,
    randomSigner,
    typedData,
    specDataHolderProxy,
    merkleTypedData,
    requestTypedData,
  }
}

describe('Merkle minting', () => {
  it('Should allow minting when an address is allowlisted on a merkle tree', async () => {
    const { badgesProxy, raftProxy, merkleTypedData, issuer, claimant, owner } =
      deployed
    const { raftTokenId } = await mintRaftToken(
      raftProxy,
      issuer.address,
      specUri,
      owner
    )
    await createSpec(badgesProxy, specUri, raftTokenId, issuer)

    const whitelistAddresses = [claimant.address, '0x1', '0x2', '0x3']

    const leafNodes = whitelistAddresses.map(addr => keccak256(addr))

    const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true })

    const merkleRoot = merkleTree.getRoot()

    merkleTypedData.value.root = merkleRoot

    const { compact } = await getSignature(
      merkleTypedData.domain,
      merkleTypedData.types,
      merkleTypedData.value,
      issuer
    )

    const merkleProof = merkleTree.getHexProof(leafNodes[0])
    await expect(
      badgesProxy
        .connect(claimant)
        .merkleTake(issuer.address, specUri, compact, merkleRoot, merkleProof)
    )

    expect(await badgesProxy.balanceOf(claimant.address)).equal(1)
  })

  it.only('Should allow minting when an address is allowlisted on a merkle tree and both issuer and recipient provide signatures', async () => {
    const {
      badgesProxy,
      raftProxy,
      merkleTypedData,
      issuer,
      claimant,
      owner,
      requestTypedData,
    } = deployed

    const { raftTokenId } = await mintRaftToken(
      raftProxy,
      issuer.address,
      specUri,
      owner
    )
    await createSpec(badgesProxy, specUri, raftTokenId, issuer)

    const whitelistAddresses = [claimant.address, '0x1', '0x2', '0x3']
    const leafNodes = whitelistAddresses.map(addr => keccak256(addr))
    const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true })
    const merkleRoot = merkleTree.getRoot()

    merkleTypedData.value.root = merkleRoot
    const { compact: issuerSignature } = await getSignature(
      merkleTypedData.domain,
      merkleTypedData.types,
      merkleTypedData.value,
      issuer
    )

    const { compact: claimantSignature } = await getSignature(
      requestTypedData.domain,
      requestTypedData.types,
      requestTypedData.value,
      claimant
    )

    const merkleProof = merkleTree.getHexProof(leafNodes[0])

    await expect(
      badgesProxy
        .connect(issuer)
        .merkleMintWithConsent(
          claimant.address.toLowerCase(),
          issuer.address.toLowerCase(),
          specUri,
          issuerSignature,
          claimantSignature,
          merkleRoot,
          merkleProof
        )
    )

    expect(await badgesProxy.balanceOf(claimant.address)).equal(1)
  })

  it('Should prevent someone who was whitelisted on a Merkle tree from minting a second time', async () => {
    const { badgesProxy, raftProxy, merkleTypedData, issuer, claimant, owner } =
      deployed
    const { raftTokenId } = await mintRaftToken(
      raftProxy,
      issuer.address,
      specUri,
      owner
    )
    await createSpec(badgesProxy, specUri, raftTokenId, issuer)

    const whitelistAddresses = [claimant.address, '0x1', '0x2', '0x3']

    const leafNodes = whitelistAddresses.map(addr => keccak256(addr))

    const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true })

    const merkleRoot = merkleTree.getRoot()
    merkleTypedData.value.root = merkleRoot

    const { compact } = await getSignature(
      merkleTypedData.domain,
      merkleTypedData.types,
      merkleTypedData.value,
      issuer
    )

    const merkleProof = merkleTree.getHexProof(leafNodes[0])

    await badgesProxy
      .connect(claimant)
      .merkleTake(issuer.address, specUri, compact, merkleRoot, merkleProof)

    expect(await badgesProxy.balanceOf(claimant.address)).equal(1)

    await expect(
      badgesProxy
        .connect(claimant)
        .merkleTake(issuer.address, specUri, compact, merkleRoot, merkleProof)
    ).to.be.revertedWith(errTokenExists)
  })

  it('Should allow someone who is part of two separate merkle trees to mint both badges', async () => {
    const { badgesProxy, raftProxy, merkleTypedData, issuer, claimant, owner } =
      deployed
    const { raftTokenId } = await mintRaftToken(
      raftProxy,
      issuer.address,
      specUri,
      owner
    )
    await createSpec(badgesProxy, specUri, raftTokenId, issuer)

    const whitelist1 = [claimant.address, '0x1', '0x2', '0x3']

    const leafNodes1 = whitelist1.map(addr => keccak256(addr))

    const merkleTree1 = new MerkleTree(leafNodes1, keccak256, {
      sortPairs: true,
    })

    const merkleRoot1 = merkleTree1.getRoot()
    merkleTypedData.value.root = merkleRoot1

    const { compact: compact1 } = await getSignature(
      merkleTypedData.domain,
      merkleTypedData.types,
      merkleTypedData.value,
      issuer
    )

    const merkleProof1 = merkleTree1.getHexProof(leafNodes1[0])

    await badgesProxy
      .connect(claimant)
      .merkleTake(issuer.address, specUri, compact1, merkleRoot1, merkleProof1)

    expect(await badgesProxy.balanceOf(claimant.address)).equal(1)

    await createSpec(badgesProxy, specUri2, raftTokenId, issuer)

    const whitelist2 = [claimant.address, '0x4', '0x5', '0x6']

    const leafNodes2 = whitelist2.map(addr => keccak256(addr))

    const merkleTree2 = new MerkleTree(leafNodes2, keccak256, {
      sortPairs: true,
    })

    const merkleRoot2 = merkleTree2.getRoot()
    merkleTypedData.value.tokenURI = specUri2
    merkleTypedData.value.root = merkleRoot2

    const { compact: compact2 } = await getSignature(
      merkleTypedData.domain,
      merkleTypedData.types,
      merkleTypedData.value,
      issuer
    )

    const merkleProof2 = merkleTree2.getHexProof(leafNodes2[0])

    await badgesProxy
      .connect(claimant)
      .merkleTake(issuer.address, specUri2, compact2, merkleRoot2, merkleProof2)

    expect(await badgesProxy.balanceOf(claimant.address)).equal(2)
  })

  it('Should reject minting when someone not on the whitelist tries to mint', async () => {
    const {
      badgesProxy,
      raftProxy,
      typedData,
      issuer,
      claimant,
      owner,
      randomSigner,
    } = deployed
    const specUri = typedData.value.tokenURI

    const { raftTokenId } = await mintRaftToken(
      raftProxy,
      issuer.address,
      specUri,
      owner
    )
    await createSpec(badgesProxy, specUri, raftTokenId, issuer)

    const whitelistAddresses = [claimant.address, '0x1', '0x2', '0x3']

    const leafNodes = whitelistAddresses.map(addr => keccak256(addr))

    const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true })

    const merkleRoot = merkleTree.getRoot()

    const { compact } = await getSignature(
      typedData.domain,
      typedData.types,
      typedData.value,
      issuer
    )
    const invalidLeafNode = keccak256(randomSigner.address)
    const merkleProof = merkleTree.getHexProof(invalidLeafNode)

    // calling connect() with a random signer is a "bad actor" trying to mint
    await expect(
      badgesProxy
        .connect(claimant)
        .merkleTake(issuer.address, specUri, compact, merkleRoot, merkleProof)
    ).to.be.revertedWith(errSafeCheckMerkleInvalidSig)
  })
})

describe('Badges', async function () {
  it('should deploy the contract with the right params', async function () {
    const { badgesProxy, raftProxy, owner, specDataHolderProxy } = deployed
    const deployedContractName = await badgesProxy.name()
    const deployedSymbolName = await badgesProxy.symbol()
    expect(deployedContractName).to.equal(name)
    expect(deployedSymbolName).to.equal(symbol)
    const deployedOwnerAddress = await badgesProxy.owner()
    expect(deployedOwnerAddress).to.equal(owner.address)
    const raftOwnerAddress = await specDataHolderProxy.getRaftAddress()
    expect(raftOwnerAddress).to.equal(raftProxy.address)
    const provider = waffle.provider
    const network = await provider.getNetwork()
    const deployedToChainId = network.chainId
    expect(deployedToChainId).to.equal(chainId)
  })
  it('should successfully set new raft contract when called by owner', async () => {
    const { owner, specDataHolderProxy } = deployed
    const raft = await ethers.getContractFactory('Raft')
    const newRaftProxy = await upgrades.deployProxy(
      raft,
      [owner.address, 'Raft', 'RAFT'],
      {
        kind: 'uups',
      }
    )
    await newRaftProxy.deployed()
    const tx = await specDataHolderProxy.setRaftAddress(newRaftProxy.address)
    await tx.wait()
    const raftAddress = await specDataHolderProxy.getRaftAddress()
    expect(raftAddress).to.equal(newRaftProxy.address)
  })

  it('should revert setting new raft address when called by non-owner', async () => {
    const { owner, randomSigner, specDataHolderProxy } = deployed
    const raft = await ethers.getContractFactory('Raft')
    const newRaftProxy = await upgrades.deployProxy(
      raft,
      [owner.address, 'Raft', 'RAFT'],
      {
        kind: 'uups',
      }
    )
    await newRaftProxy.deployed()
    await expect(
      specDataHolderProxy
        .connect(randomSigner)
        .setRaftAddress(newRaftProxy.address)
    ).to.be.revertedWith(errNotOwner)
  })

  it('should match off-chain hash to on-chain hash', async () => {
    const { badgesProxy, typedData } = deployed
    const offChainHash = _TypedDataEncoder.hash(
      typedData.domain,
      typedData.types,
      typedData.value
    )
    const onChainHash = await badgesProxy.getAgreementHash(
      typedData.value.active,
      typedData.value.passive,
      typedData.value.tokenURI
    )
    expect(offChainHash).to.equal(onChainHash)
  })
})
