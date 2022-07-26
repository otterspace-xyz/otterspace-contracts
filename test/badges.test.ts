import { expect } from 'chai'
import { ethers } from 'hardhat'
import { Badges, Raft } from '../typechain-types'
import { BigNumberish, Wallet } from 'ethers'
import type { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { waffle } from 'hardhat'
import { LogDescription, splitSignature, _TypedDataEncoder } from 'ethers/lib/utils'
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers'

const name = 'Otter'
const symbol = 'OTTR'
const version = '1'
const chainId = 31337
const specUri = 'some spec uri'

const errNotOwner = 'Ownable: caller is not the owner'
const errMintFailed = 'mintAuthorizedBadge: badge minting failed'
const errSpecNotRegistered = 'mintAuthorizedBadge: spec is not registered'
const errSpecAlreadyRegistered = 'createSpecAsRaftOwner: spec already registered'
const errNotRaftOwner = 'createSpecAsRaftOwner: unauthorized'
const errInvalidSig = '_safeCheckAgreement: invalid signature'

async function createSpec(
  badgesContract: Badges,
  specUri: string,
  raftTokenId: BigNumberish,
  signer: SignerWithAddress
) {
  const txn = await badgesContract.connect(signer).createSpecAsRaftOwner(specUri, raftTokenId)
  const txReceipt = await txn.wait()
  expect(txReceipt.status).equal(1)

  return await getSpecCreatedEventLogData(txn.hash, badgesContract)
}

async function mintRaftToken(raftContract: Raft, toAddress: string, raftTokenUri: string, signer: SignerWithAddress) {
  const txn = await raftContract.connect(signer).mint(toAddress, raftTokenUri)
  const txReceipt = await txn.wait()
  expect(txReceipt.status).equal(1)

  const [transferEvent] = txReceipt.events!
  const { tokenId: rawTokenId } = transferEvent.args!
  const raftTokenId = ethers.BigNumber.from(rawTokenId).toNumber()
  expect(raftTokenId).gt(0)

  const raftTokenOwner = await raftContract.ownerOf(raftTokenId)
  expect(raftTokenOwner).equal(toAddress)

  return { raftTokenOwner, raftTokenId }
}

async function getSignature(domain: any, types: any, value: any, signer: SignerWithAddress) {
  const signature = await signer._signTypedData(domain, types, value)
  const { compact } = splitSignature(signature)
  return { compact }
}

enum EventType {
  Badges_BadgeMinted = 'BadgeMinted',
  Badges_SpecCreated = 'SpecCreated',
  ERC4973_Transfer = 'Transfer',
}

async function getParsedLogs(txnHash: string, badgesContract: Badges) {
  const txnReceipt = await waffle.provider.getTransactionReceipt(txnHash)

  const log = txnReceipt.logs[0]

  let parsedLogs: LogDescription[] = []
  txnReceipt.logs.forEach(log => {
    parsedLogs.push(badgesContract.interface.parseLog(log))
  })

  return parsedLogs
}

async function getTransferEventLogData(txnHash: string, badgesContract: Badges) {
  const parsedLogs = await getParsedLogs(txnHash, badgesContract)
  const transferLog = parsedLogs.find(l => l.name == EventType.ERC4973_Transfer)

  const from = transferLog?.args['from']
  const to = transferLog?.args['to']
  const tokenId = transferLog?.args['tokenId'] as BigNumberish

  return { from, to, tokenId }
}

async function getBadgeMintedEventLogData(txnHash: string, badgesContract: Badges) {
  const parsedLogs = await getParsedLogs(txnHash, badgesContract)
  const transferLog = parsedLogs.find(l => l.name == EventType.Badges_BadgeMinted)

  const from = transferLog?.args['from']
  const to = transferLog?.args['to']
  const specUri = transferLog?.args['specUri']
  const tokenId = transferLog?.args['tokenId'] as BigNumberish

  return { from, to, specUri, tokenId }
}

async function getSpecCreatedEventLogData(txnHash: string, badgesContract: Badges) {
  const parsedLogs = await getParsedLogs(txnHash, badgesContract)
  const transferLog = parsedLogs.find(l => l.name == EventType.Badges_SpecCreated)

  const to = transferLog?.args['to']
  const specUri = transferLog?.args['specUri']
  const raftTokenId = transferLog?.args['raftTokenId'] as BigNumberish
  const raftAddress = transferLog?.args['raftAddress']

  return { to, specUri, raftTokenId, raftAddress }
}

async function deployContractFixture() {
  const [owner, issuer, claimant, randomSigner] = await ethers.getSigners()

  const raft = await ethers.getContractFactory('Raft')
  const raftContract = await raft.deploy(owner.address, name, symbol)
  await raftContract.deployed()

  const badges = await ethers.getContractFactory('Badges')
  const badgesContract = await badges.deploy(name, symbol, version, raftContract.address, owner.address)
  await badgesContract.deployed()

  const typedData = {
    domain: {
      name: name,
      version: version,
      chainId,
      verifyingContract: badgesContract.address,
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
  return { badgesContract, raftContract, owner, issuer, claimant, randomSigner, typedData }
}

describe('Badge Specs', () => {
  it('should register a spec successfully', async function () {
    // deploy contracts
    const { badgesContract, raftContract, typedData, issuer, claimant, owner, randomSigner } = await loadFixture(
      deployContractFixture
    )
    const specUri = typedData.value.tokenURI

    // mint raft
    const { raftTokenId } = await mintRaftToken(raftContract, issuer.address, specUri, owner)

    // create spec
    const specCreatedEventData = await createSpec(badgesContract, specUri, raftTokenId, issuer)

    expect(specCreatedEventData.to).equal(issuer.address)
    expect(specCreatedEventData.specUri).equal(specUri)
    expect(specCreatedEventData.raftTokenId).equal(raftTokenId)
    expect(specCreatedEventData.raftAddress).equal(raftContract.address)

    const raftTokenIdOfSpec = await badgesContract.getRaftTokenIdOf(specUri)

    expect(raftTokenIdOfSpec).to.equal(raftTokenId)
  })

  it('should fail to register a spec if the spec URI is already registered', async function () {
    // deploy contracts
    const { badgesContract, raftContract, typedData, issuer, claimant, owner, randomSigner } = await loadFixture(
      deployContractFixture
    )
    const specUri = typedData.value.tokenURI

    // mint raft
    const { raftTokenId } = await mintRaftToken(raftContract, issuer.address, specUri, owner)

    // create spec 1st time
    await createSpec(badgesContract, specUri, raftTokenId, issuer)

    // create spec 2nd time time
    await expect(createSpec(badgesContract, specUri, raftTokenId, issuer)).to.be.revertedWith(errSpecAlreadyRegistered)
  })

  it('should fail to register a spec if the caller is not a raft token owner', async () => {
    // deploy contracts
    const { badgesContract, raftContract, typedData, issuer, owner, randomSigner } = await loadFixture(
      deployContractFixture
    )
    const specUri = typedData.value.tokenURI

    // mint raft
    const { raftTokenId } = await mintRaftToken(raftContract, randomSigner.address, specUri, owner)

    // create spec when issuer has not minted raft token
    await expect(createSpec(badgesContract, specUri, raftTokenId, issuer)).to.be.revertedWith(errNotRaftOwner)
  })
})

describe('Badges', async function () {
  it('should deploy the contract with the right params', async function () {
    const { badgesContract, raftContract, owner } = await loadFixture(deployContractFixture)

    const deployedContractName = await badgesContract.name()
    const deployedSymbolName = await badgesContract.symbol()
    expect(deployedContractName).to.equal(name)
    expect(deployedSymbolName).to.equal(symbol)

    const deployedOwnerAddress = await badgesContract.owner()
    expect(deployedOwnerAddress).to.equal(owner.address)

    const raftOwnerAddress = await badgesContract.getRaftAddress()
    expect(raftOwnerAddress).to.equal(raftContract.address)

    const provider = waffle.provider
    const network = await provider.getNetwork()
    const deployedToChainId = network.chainId
    expect(deployedToChainId).to.equal(chainId)
  })

  it('should successfully set new raft address when called by owner', async () => {
    const { badgesContract, raftContract, owner } = await loadFixture(deployContractFixture)

    const raft = await ethers.getContractFactory('Raft')
    const newRaftContract = await raft.deploy(owner.address, name, symbol)
    await raftContract.deployed()

    await badgesContract.connect(owner).setRaftAddress(newRaftContract.address)
    const raftAddress = await badgesContract.getRaftAddress()
    expect(raftAddress).to.equal(newRaftContract.address)
  })

  it('should revert setting new raft address when called by non-owner', async () => {
    const { badgesContract, raftContract, owner, randomSigner } = await loadFixture(deployContractFixture)

    const raft = await ethers.getContractFactory('Raft')
    const newRaftContract = await raft.deploy(owner.address, name, symbol)
    await raftContract.deployed()

    await expect(badgesContract.connect(randomSigner).setRaftAddress(newRaftContract.address)).to.be.revertedWith(
      errNotOwner
    )
  })

  it('should match off-chain hash to on-chain hash', async () => {
    const { badgesContract, typedData } = await loadFixture(deployContractFixture)
    const offChainHash = _TypedDataEncoder.hash(typedData.domain, typedData.types, typedData.value)

    const onChainHash = await badgesContract.getHash(
      typedData.value.active,
      typedData.value.passive,
      typedData.value.tokenURI
    )

    expect(offChainHash).to.equal(onChainHash)
  })

  it('should successfully mint badge', async function () {
    // deploy contracts
    const { badgesContract, raftContract, typedData, issuer, claimant, owner } = await loadFixture(
      deployContractFixture
    )
    const specUri = typedData.value.tokenURI

    // mint raft
    const { raftTokenId } = await mintRaftToken(raftContract, issuer.address, specUri, owner)

    // create spec
    await createSpec(badgesContract, specUri, raftTokenId, issuer)

    // get signature
    const { compact } = await getSignature(typedData.domain, typedData.types, typedData.value, issuer)

    // take's "from" is the issuer
    // take's msg.sender is the claimant
    const txn = await badgesContract.connect(claimant).take(typedData.value.passive, typedData.value.tokenURI, compact)
    await txn.wait()

    const transferEventData = await getTransferEventLogData(txn.hash, badgesContract)
    // currently the ERC4973 is hardcoding from to 0 in the event - https://github.com/rugpullindex/ERC4973/issues/39
    // expect(transferEventData.from).equal(typedData.value.passive) // issuer.address,
    expect(transferEventData.to).equal(typedData.value.active) // claimant.address
    expect(transferEventData.tokenId).gt(0)

    const badgeEventData = await getBadgeMintedEventLogData(txn.hash, badgesContract)
    // expect(badgeEventData.from).equal(typedData.value.passive) // issuer.address
    expect(badgeEventData.to).equal(typedData.value.active) // claimant.address

    expect(badgeEventData.specUri).equal(specUri)

    expect(badgeEventData.tokenId).gt(0)

    const ownerOfMintedToken = await badgesContract.ownerOf(transferEventData.tokenId)
    expect(ownerOfMintedToken).to.equal(claimant.address)

    const balanceOfClaimant = await badgesContract.balanceOf(claimant.address)
    expect(balanceOfClaimant).to.equal(1)

    const uriOfToken = await badgesContract.tokenURI(transferEventData.tokenId)
    expect(uriOfToken).to.equal(typedData.value.tokenURI)
  })

  it('should fail to mint badge when trying as an unauthorized claimant', async () => {
    // deploy contracts
    const { badgesContract, raftContract, typedData, issuer, claimant, owner } = await loadFixture(
      deployContractFixture
    )
    const specUri = typedData.value.tokenURI

    // mint raft
    const { raftTokenId } = await mintRaftToken(raftContract, issuer.address, specUri, owner)

    // create spec
    await createSpec(badgesContract, specUri, raftTokenId, issuer)

    // get signature
    const { compact } = await getSignature(typedData.domain, typedData.types, typedData.value, issuer)

    // unauthorized claimant
    const unauthorizedClaimant = Wallet.createRandom()

    await expect(
      badgesContract.connect(claimant).take(unauthorizedClaimant.address, specUri, compact)
    ).to.be.revertedWith(errInvalidSig)
  })

  it('should fail to mint badge when signed by a random issuer', async () => {
    // deploy contracts
    const { badgesContract, raftContract, typedData, issuer, claimant, owner, randomSigner } = await loadFixture(
      deployContractFixture
    )
    const specUri = typedData.value.tokenURI

    // mint raft
    const { raftTokenId } = await mintRaftToken(raftContract, issuer.address, specUri, owner)

    // create spec
    await createSpec(badgesContract, specUri, raftTokenId, issuer)

    // get signature by random signer
    const { compact } = await getSignature(typedData.domain, typedData.types, typedData.value, randomSigner)

    await expect(badgesContract.connect(claimant).take(typedData.value.passive, specUri, compact)).to.be.revertedWith(
      errInvalidSig
    )
  })

  it('should fail to mint badge when using incorrect token uri', async () => {
    // deploy contracts
    const { badgesContract, raftContract, typedData, issuer, claimant, owner, randomSigner } = await loadFixture(
      deployContractFixture
    )
    const specUri = typedData.value.tokenURI

    // mint raft
    const { raftTokenId } = await mintRaftToken(raftContract, issuer.address, specUri, owner)

    // create spec
    await createSpec(badgesContract, specUri, raftTokenId, issuer)

    // prep incorrect uri to be signed
    typedData.value.tokenURI = 'http://icorrect-uri'

    // get signature
    const { compact } = await getSignature(typedData.domain, typedData.types, typedData.value, issuer)

    await expect(badgesContract.connect(claimant).take(typedData.value.passive, specUri, compact)).to.be.revertedWith(
      errInvalidSig
    )
  })

  it('should fail to mint badge when using an unregistered spec', async () => {
    // deploy contracts
    const { badgesContract, raftContract, typedData, issuer, claimant, owner, randomSigner } = await loadFixture(
      deployContractFixture
    )
    const specUri = typedData.value.tokenURI

    // mint raft
    const { raftTokenId } = await mintRaftToken(raftContract, issuer.address, specUri, owner)

    // get signature
    const { compact } = await getSignature(typedData.domain, typedData.types, typedData.value, issuer)

    await expect(badgesContract.connect(claimant).take(typedData.value.passive, specUri, compact)).to.be.revertedWith(
      errSpecNotRegistered
    )
  })
})
