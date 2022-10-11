import { expect } from 'chai'
import { ethers, upgrades } from 'hardhat'
import { Badges, Raft } from '../typechain-types'
import { BigNumberish, Wallet } from 'ethers'
import type { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { waffle } from 'hardhat'
import { LogDescription, splitSignature, _TypedDataEncoder } from 'ethers/lib/utils'
import { AnyNaptrRecord } from 'dns'
import { MerkleTree } from 'merkletreejs'
import keccak256 from 'keccak256'

const name = 'Otter'
const symbol = 'OTTR'
const version = '1'
// ideally chainId would be dynamic depending upon if you're running tests locally or on a
//live network and automaticall set the chainId to the correct value.
const chainId = 31337
const specUri = 'some spec uri'
const reasonChoice = 1

const errNotOwner = 'Ownable: caller is not the owner'
const errSpecNotRegistered = 'mint: spec is not registered'
const errSpecAlreadyRegistered = 'createSpec: spec already registered'
const errNotRaftOwner = 'createSpec: unauthorized'
const errInvalidSig = 'safeCheckAgreement: invalid signature'
const tokenExistsErr = 'mint: tokenID exists'
const tokenDoesntExistErr = "tokenExists: token doesn't exist"
const errNotRevoked = 'reinstateBadge: badge not revoked'
const errBadgeAlreadyRevoked = 'revokeBadge: badge already revoked'
const errMerkleAlreadyUsed = 'safeCheckAgreementMerkle: already used'

let deployed: any

// fix ts badgesProxy: any
async function createSpec(badgesProxy: any, specUri: string, raftTokenId: BigNumberish, signer: SignerWithAddress) {
  const txn = await badgesProxy.connect(signer).createSpec(specUri, raftTokenId)
  const txReceipt = await txn.wait()
  expect(txReceipt.status).equal(1)
  return await getSpecCreatedEventLogData(txn.hash, badgesProxy)
}

async function mintBadge() {
  // deploy contracts
  const { badgesProxy, raftProxy, typedData, issuer, claimant, owner } = deployed
  const specUri = typedData.value.tokenURI
  // mint raft
  const { raftTokenId } = await mintRaftToken(raftProxy, issuer.address, specUri, owner)
  // create spec
  await createSpec(badgesProxy, specUri, raftTokenId, issuer)
  // get signature
  const { compact } = await getSignature(typedData.domain, typedData.types, typedData.value, issuer)
  // take's "from" is the issuer
  // take's msg.sender is the claimant

  const txn = await badgesProxy.connect(claimant).take(typedData.value.passive, typedData.value.tokenURI, compact)
  await txn.wait()
  const transferEventData = await getTransferEventLogData(txn.hash, badgesProxy)
  // currently the ERC4973 is hardcoding from to 0 in the event - https://github.com/rugpullindex/ERC4973/issues/39
  // expect(transferEventData.from).equal(typedData.value.passive) // issuer.address,
  expect(transferEventData.to).equal(typedData.value.active) // claimant.address
  expect(transferEventData.tokenId).gt(0)

  const ownerOfMintedToken = await badgesProxy.ownerOf(transferEventData.tokenId)
  expect(ownerOfMintedToken).to.equal(claimant.address)
  const balanceOfClaimant = await badgesProxy.balanceOf(claimant.address)
  expect(balanceOfClaimant).to.equal(1)
  const uriOfToken = await badgesProxy.tokenURI(transferEventData.tokenId)
  expect(uriOfToken).to.equal(typedData.value.tokenURI)
  return { raftTokenId, badgeId: transferEventData.tokenId }
}

async function mintRaftToken(raftProxy: any, toAddress: string, raftTokenUri: string, signer: SignerWithAddress) {
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

async function getParsedLogs(txnHash: string, badgesProxy: any) {
  const txnReceipt = await waffle.provider.getTransactionReceipt(txnHash)

  const log = txnReceipt.logs[0]

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

async function getSpecCreatedEventLogData(txnHash: string, badgesProxy: Badges) {
  const parsedLogs = await getParsedLogs(txnHash, badgesProxy)
  const transferLog = parsedLogs.find(l => l.name == EventType.Badges_SpecCreated)

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
  const [owner, issuer, claimant, randomSigner, merkleIssuer] = await ethers.getSigners()

  const raft = await ethers.getContractFactory('Raft')
  const raftProxy = await upgrades.deployProxy(raft, [owner.address, 'Raft', 'RAFT'], {
    kind: 'uups',
  })

  await raftProxy.deployed()

  const specDataHolder = await ethers.getContractFactory('SpecDataHolder')
  const specDataHolderProxy = await upgrades.deployProxy(specDataHolder, [raftProxy.address, owner.address], {
    kind: 'uups',
  })

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

  deployed = {
    badgesProxy,
    raftProxy,
    owner,
    issuer,
    claimant,
    randomSigner,
    typedData,
    specDataHolderProxy,
  }
}

describe('Merkle minting', () => {
  it('Happy path: should allow minting when an address is whitelisted on a merkle tree', async () => {
    const { badgesProxy, raftProxy, typedData, issuer, claimant, owner } = deployed
    const specUri = typedData.value.tokenURI
    // SETUP (step 0)
    const { raftTokenId } = await mintRaftToken(raftProxy, issuer.address, specUri, owner)
    await createSpec(badgesProxy, specUri, raftTokenId, issuer)

    // ===== step 1: the issuer whitelists a bunch of addresses
    const whitelistAddresses = [claimant.address, '0x1', '0x2', '0x3']

    // map over addresses to get leaf nodes
    const leafNodes = whitelistAddresses.map(addr => keccak256(addr))

    // create merkle tree
    const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true })

    // create merkle root
    const merkleRoot = merkleTree.getRoot()

    // create signature
    const { compact } = await getSignature(typedData.domain, typedData.types, typedData.value, issuer)
    // ===== at this point we will store signature and `whitelistAddresses` in the db

    // ===== step 2: simulate the claimant minting a badge

    // given the claimant's address, get a merkleProof
    const merkleProof = merkleTree.getHexProof(leafNodes[0])

    // pass merkleRoot and merkleProof to the badges contract
    // badges contract will check to see if the proof is valid
    await badgesProxy
      .connect(claimant)
      .mintWithMerklePermission(issuer.address, merkleRoot, merkleProof, specUri, compact)

    // ===== step 3: check that the claimant has the badge
    expect(await badgesProxy.balanceOf(claimant.address)).equal(1)
  })

  // todo: reject when someone who has already claimed tries to claim again
  it.only('Should prevent someone who was whitelisted on a Merkle tree from minting a second time', async () => {
    const { badgesProxy, raftProxy, typedData, issuer, claimant, owner } = deployed
    const specUri = typedData.value.tokenURI
    // SETUP (step 0)
    const { raftTokenId } = await mintRaftToken(raftProxy, issuer.address, specUri, owner)
    await createSpec(badgesProxy, specUri, raftTokenId, issuer)

    // ===== step 1: the issuer whitelists a bunch of addresses
    const whitelistAddresses = [claimant.address, '0x1', '0x2', '0x3']

    // map over addresses to get leaf nodes
    const leafNodes = whitelistAddresses.map(addr => keccak256(addr))

    // create merkle tree
    const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true })

    // create merkle root
    const merkleRoot = merkleTree.getRoot()

    // create signature
    const { compact } = await getSignature(typedData.domain, typedData.types, typedData.value, issuer)
    // ===== at this point we will store signature and `whitelistAddresses` in the db

    // ===== step 2: simulate the claimant minting a badge

    // given the claimant's address, get a merkleProof
    const merkleProof = merkleTree.getHexProof(leafNodes[0])

    // pass merkleRoot and merkleProof to the badges contract
    // badges contract will check to see if the proof is valid
    await badgesProxy
      .connect(claimant)
      .mintWithMerklePermission(issuer.address, merkleRoot, merkleProof, specUri, compact)

    // ===== step 3: check that the claimant has the badge
    expect(await badgesProxy.balanceOf(claimant.address)).equal(1)

    // ===== step 4: simulate the claimant minting a badge again
    console.log('got the first mint')

    // expect the second attempt to fail
    await expect(
      badgesProxy.connect(claimant).mintWithMerklePermission(issuer.address, merkleRoot, merkleProof, specUri, compact)
    ).to.be.revertedWith(errMerkleAlreadyUsed)
  })

  //  todo: ensure that someone who is part of two different merkle trees can claim on each tree

  it('Should reject minting when someone not on the whitelist tries to mint', async () => {
    const { badgesProxy, raftProxy, typedData, issuer, claimant, owner, randomSigner } = deployed
    const specUri = typedData.value.tokenURI

    const { raftTokenId } = await mintRaftToken(raftProxy, issuer.address, specUri, owner)
    await createSpec(badgesProxy, specUri, raftTokenId, issuer)

    const whitelistAddresses = [claimant.address, '0x1', '0x2', '0x3']

    const leafNodes = whitelistAddresses.map(addr => keccak256(addr))

    const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true })

    const merkleRoot = merkleTree.getRoot()

    const { compact } = await getSignature(typedData.domain, typedData.types, typedData.value, issuer)

    const merkleProof = merkleTree.getHexProof(leafNodes[0])

    // calling connect() with a random signer is a "bad actor" trying to mint
    await expect(
      badgesProxy
        .connect(randomSigner)
        .mintWithMerklePermission(issuer.address, merkleRoot, merkleProof, specUri, compact)
    ).to.be.revertedWith('invalid proof')
  })
})

describe('Proxy upgrades', () => {
  it('Should upgrade the Raft contract then create raft/spec/badge', async () => {
    // deploy contracts
    const { raftProxy } = deployed

    const raftV2 = await ethers.getContractFactory('RaftV2')
    const upgradedV2Contract = await upgrades.upgradeProxy(raftProxy.address, raftV2)
    await upgradedV2Contract.deployed()

    const v2 = await upgradedV2Contract.getVersion()
    // expect(v2).equal(2)
    await mintBadge()
  })

  it('Should upgrade the Badge contract then create raft/spec/badge', async () => {
    // deploy contracts
    const { badgesProxy } = deployed

    const badgesV2 = await ethers.getContractFactory('BadgesV2')
    const upgradedV2Contract = await upgrades.upgradeProxy(badgesProxy.address, badgesV2)
    await upgradedV2Contract.deployed()

    const v2 = await upgradedV2Contract.getVersion()
    expect(v2).equal(2)

    await mintBadge()
  })

  it('Should upgrade then instantiate new variable right after', async () => {
    const { badgesProxy } = deployed

    const badgesV2 = await ethers.getContractFactory('BadgesV2')
    const upgradedV2Contract = await upgrades.upgradeProxy(badgesProxy.address, badgesV2)
    await upgradedV2Contract.deployed()
    await upgradedV2Contract.setNewVar()
    const newVar = await upgradedV2Contract.myNewVar()
    expect(newVar).equal(9)
    await expect(upgradedV2Contract.setNewVar()).to.be.revertedWith('Var is already set')
  })

  it('Should upgrade the SpecDataHolder contract then create raft/spec/badge', async () => {
    // deploy contracts
    const { specDataHolderProxy } = deployed

    const specDataHolderV2 = await ethers.getContractFactory('SpecDataHolderV2')
    const upgradedV2Contract = await upgrades.upgradeProxy(specDataHolderProxy.address, specDataHolderV2)
    await upgradedV2Contract.deployed()

    const v2 = await upgradedV2Contract.getVersion()
    expect(v2).equal(2)

    await mintBadge()
  })
})

describe('Badge Specs', () => {
  it('should register a spec successfully', async function () {
    // deploy contracts
    const { badgesProxy, raftProxy, typedData, issuer, owner, specDataHolderProxy } = deployed

    const specUri = typedData.value.tokenURI

    // mint raft
    const { raftTokenId } = await mintRaftToken(raftProxy, issuer.address, specUri, owner)

    // create spec
    const specCreatedEventData = await createSpec(badgesProxy, specUri, raftTokenId, issuer)

    expect(specCreatedEventData.to).equal(issuer.address)
    expect(specCreatedEventData.specUri).equal(specUri)
    expect(specCreatedEventData.raftTokenId).equal(raftTokenId)
    expect(specCreatedEventData.raftAddress).equal(raftProxy.address)

    const raftTokenIdOfSpec = await specDataHolderProxy.getRaftTokenId(specUri)

    expect(raftTokenIdOfSpec).to.equal(raftTokenId)
  })

  it('should fail to register a spec if the spec URI is already registered', async function () {
    // deploy contracts
    const { badgesProxy, raftProxy, typedData, issuer, owner } = deployed
    const specUri = typedData.value.tokenURI

    // mint raft
    const { raftTokenId } = await mintRaftToken(raftProxy, issuer.address, specUri, owner)

    // create spec 1st time
    await createSpec(badgesProxy, specUri, raftTokenId, issuer)

    // create spec 2nd time time
    await expect(createSpec(badgesProxy, specUri, raftTokenId, issuer)).to.be.revertedWith(errSpecAlreadyRegistered)
  })

  it('should fail to register a spec if the caller is not a raft token owner', async () => {
    // deploy contracts
    const { badgesProxy, raftProxy, typedData, issuer, owner, randomSigner } = deployed
    const specUri = typedData.value.tokenURI

    // mint raft
    const { raftTokenId } = await mintRaftToken(raftProxy, randomSigner.address, specUri, owner)

    // create spec when issuer has not minted raft token
    await expect(createSpec(badgesProxy, specUri, raftTokenId, issuer)).to.be.revertedWith(errNotRaftOwner)
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
    const newRaftProxy = await upgrades.deployProxy(raft, [owner.address, 'Raft', 'RAFT'], {
      kind: 'uups',
    })
    await newRaftProxy.deployed()
    const tx = await specDataHolderProxy.setRaftAddress(newRaftProxy.address)
    await tx.wait()
    const raftAddress = await specDataHolderProxy.getRaftAddress()
    expect(raftAddress).to.equal(newRaftProxy.address)
  })

  it('should revert setting new raft address when called by non-owner', async () => {
    const { owner, randomSigner, specDataHolderProxy } = deployed
    const raft = await ethers.getContractFactory('Raft')
    const newRaftProxy = await upgrades.deployProxy(raft, [owner.address, 'Raft', 'RAFT'], {
      kind: 'uups',
    })
    await newRaftProxy.deployed()
    await expect(specDataHolderProxy.connect(randomSigner).setRaftAddress(newRaftProxy.address)).to.be.revertedWith(
      errNotOwner
    )
  })

  it('should match off-chain hash to on-chain hash', async () => {
    const { badgesProxy, typedData } = deployed
    const offChainHash = _TypedDataEncoder.hash(typedData.domain, typedData.types, typedData.value)
    const onChainHash = await badgesProxy.getAgreementHash(
      typedData.value.active,
      typedData.value.passive,
      typedData.value.tokenURI
    )
    expect(offChainHash).to.equal(onChainHash)
  })

  it('should successfully mint badge', async function () {
    mintBadge()
  })

  it('should fail when trying to claim using a voucher from another issuer for the same spec', async function () {
    // deploy contracts
    const { badgesProxy, raftProxy, typedData, issuer, claimant, owner } = deployed
    // first we issue the Raft token to the issuer
    const raftOwner = issuer
    const { raftTokenId } = await mintRaftToken(raftProxy, raftOwner.address, specUri, owner)

    await createSpec(badgesProxy, specUri, raftTokenId, raftOwner)

    const { compact } = await getSignature(typedData.domain, typedData.types, typedData.value, raftOwner)

    const txn = await badgesProxy.connect(claimant).take(typedData.value.passive, typedData.value.tokenURI, compact)
    await txn.wait()
    const transferEventData = await getTransferEventLogData(txn.hash, badgesProxy)

    expect(transferEventData.to).equal(typedData.value.active) // claimant.address
    expect(transferEventData.tokenId).gt(0)

    const ownerOfMintedToken = await badgesProxy.ownerOf(transferEventData.tokenId)
    expect(ownerOfMintedToken).to.equal(claimant.address)
    const balanceOfClaimant = await badgesProxy.balanceOf(claimant.address)
    expect(balanceOfClaimant).to.equal(1)
    const uriOfToken = await badgesProxy.tokenURI(transferEventData.tokenId)
    expect(uriOfToken).to.equal(typedData.value.tokenURI)

    // transfer the Raft token to someone else so that we can test the second minting
    const newRaftOwner = owner
    // raft owner should approve the transfer to "owner"
    await raftProxy.connect(raftOwner).approve(newRaftOwner.address, raftTokenId)

    // make the transfer
    await raftProxy.connect(raftOwner).transferFrom(raftOwner.address, newRaftOwner.address, raftTokenId)
    const ownerOfTransferredToken = await raftProxy.ownerOf(raftTokenId)
    expect(ownerOfTransferredToken).to.equal(newRaftOwner.address)
    // for TX2 the raft owner is the issuer

    typedData.value.passive = newRaftOwner.address
    // new owner should create a signature
    const { compact: compactSig2 } = await getSignature(
      typedData.domain,
      typedData.types,
      typedData.value,
      newRaftOwner
    )

    // claimant should again try to mint a badge
    await expect(
      badgesProxy.connect(claimant).take(typedData.value.passive, typedData.value.tokenURI, compactSig2)
    ).to.be.revertedWith(tokenExistsErr)
  })

  it('should fail to mint badge when trying as an unauthorized claimant', async () => {
    // deploy contracts
    const { badgesProxy, raftProxy, typedData, issuer, claimant, owner } = deployed
    const specUri = typedData.value.tokenURI
    // mint raft
    const { raftTokenId } = await mintRaftToken(raftProxy, issuer.address, specUri, owner)
    // create spec
    await createSpec(badgesProxy, specUri, raftTokenId, issuer)
    // get signature
    const { compact } = await getSignature(typedData.domain, typedData.types, typedData.value, issuer)
    // unauthorized claimant
    const unauthorizedClaimant = Wallet.createRandom()
    await expect(badgesProxy.connect(claimant).take(unauthorizedClaimant.address, specUri, compact)).to.be.revertedWith(
      errInvalidSig
    )
  })
  it('should fail to mint badge when signed by a random issuer', async () => {
    // deploy contracts
    const { badgesProxy, raftProxy, typedData, issuer, claimant, owner, randomSigner } = deployed
    const specUri = typedData.value.tokenURI
    // mint raft
    const { raftTokenId } = await mintRaftToken(raftProxy, issuer.address, specUri, owner)
    // create spec
    await createSpec(badgesProxy, specUri, raftTokenId, issuer)
    // get signature by random signer
    const { compact } = await getSignature(typedData.domain, typedData.types, typedData.value, randomSigner)
    await expect(badgesProxy.connect(claimant).take(typedData.value.passive, specUri, compact)).to.be.revertedWith(
      errInvalidSig
    )
  })
  it('should fail to mint badge when using incorrect token uri', async () => {
    // deploy contracts
    const { badgesProxy, raftProxy, typedData, issuer, claimant, owner } = deployed
    const specUri = typedData.value.tokenURI
    // mint raft
    const { raftTokenId } = await mintRaftToken(raftProxy, issuer.address, specUri, owner)
    // create spec
    await createSpec(badgesProxy, specUri, raftTokenId, issuer)
    // prep incorrect uri to be signed
    typedData.value.tokenURI = 'http://icorrect-uri'
    // get signature
    const { compact } = await getSignature(typedData.domain, typedData.types, typedData.value, issuer)
    await expect(badgesProxy.connect(claimant).take(typedData.value.passive, specUri, compact)).to.be.revertedWith(
      errInvalidSig
    )
  })
  it('should fail to mint badge when using an unregistered spec', async () => {
    // deploy contracts
    const { badgesProxy, raftProxy, typedData, issuer, claimant, owner } = deployed
    const specUri = typedData.value.tokenURI
    // mint raft
    const { raftTokenId } = await mintRaftToken(raftProxy, issuer.address, specUri, owner)
    // get signature
    const { compact } = await getSignature(typedData.domain, typedData.types, typedData.value, issuer)
    await expect(badgesProxy.connect(claimant).take(typedData.value.passive, specUri, compact)).to.be.revertedWith(
      errSpecNotRegistered
    )
  })

  it('Should revoke a badge, confirm its revoked, then reinstate', async () => {
    const { raftTokenId, badgeId } = await mintBadge()
    const { badgesProxy, issuer } = deployed
    // revoke the badge
    await badgesProxy.connect(issuer).revokeBadge(raftTokenId, badgeId, reasonChoice)

    // test to make sure that revocation worked
    expect(await badgesProxy.connect(issuer).isBadgeValid(badgeId)).to.equal(false)

    // reinstate the badge
    await badgesProxy.connect(issuer).reinstateBadge(raftTokenId, badgeId)

    // test to make sure that reinstatement worked
    expect(await badgesProxy.connect(issuer).isBadgeValid(badgeId)).to.equal(true)
  })

  it('Should fail to revoke a badge if passed an invalid tokenId', async () => {
    const { raftTokenId, badgeId } = await mintBadge()
    const { badgesProxy, issuer } = deployed

    await expect(badgesProxy.connect(issuer).revokeBadge(raftTokenId, 123, reasonChoice)).to.be.revertedWith(
      tokenDoesntExistErr
    )
  })

  it('Should fail to reinstate a badge that is not revoked', async () => {
    const { raftTokenId, badgeId } = await mintBadge()
    const { badgesProxy, issuer } = deployed

    expect(await badgesProxy.connect(issuer).isBadgeValid(badgeId)).to.equal(true)

    await expect(badgesProxy.connect(issuer).reinstateBadge(raftTokenId, badgeId)).to.be.revertedWith(errNotRevoked)
  })

  it('Should fail to revoke a badge if its already revoked', async () => {
    const { raftTokenId, badgeId } = await mintBadge()
    const { badgesProxy, issuer } = deployed
    // revoke the badge
    await badgesProxy.connect(issuer).revokeBadge(raftTokenId, badgeId, reasonChoice)

    // test to make sure that revocation worked
    expect(await badgesProxy.connect(issuer).isBadgeValid(badgeId)).to.equal(false)
    console.log('here')
    await expect(badgesProxy.connect(issuer).revokeBadge(raftTokenId, badgeId, reasonChoice)).to.be.revertedWith(
      errBadgeAlreadyRevoked
    )
  })
})
