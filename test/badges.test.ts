import { expect } from 'chai'
import { ethers } from 'hardhat'
import { Badges } from '../typechain-types'
import { Wallet } from 'ethers'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { waffle } from 'hardhat'
import { splitSignature, _TypedDataEncoder } from 'ethers/lib/utils'
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers'

describe('Badges', async function () {
  const name = 'Otter'
  const symbol = 'OTTR'
  const version = '1'
  const chainId = 31337
  const specUri = 'some spec uri'
  const incorrectUri = 'https://some-incorrect-uri.com'

  async function deployContractFixture() {
    const badges = await ethers.getContractFactory('Badges')
    const [owner, issuer, claimant, claimant2] = await ethers.getSigners()

    const badgesContract = await badges.deploy(name, symbol, version)
    await badgesContract.deployed()

    const raft = await ethers.getContractFactory('Raft')
    const raftContract = await raft.deploy(owner.address, name, symbol)
    await raftContract.deployed()

    const tx = await raftContract.mint(issuer.address, specUri)
    const txReceipt = await tx.wait()

    const [transferEvent] = txReceipt.events!
    const { tokenId: rawTokenId } = transferEvent.args!
    const raftTokenId = ethers.BigNumber.from(rawTokenId).toNumber()
    const tokenOwner = await raftContract.ownerOf(raftTokenId)
    expect(tokenOwner).to.equal(issuer.address)

    const specTx = await badgesContract.createSpecAsRaftOwner(specUri, raftTokenId)
    await specTx.wait()
    const specExists = await badgesContract.checkIfSpecExists(specUri)
    expect(specExists).to.equal(true)

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
    return { badges, badgesContract, owner, issuer, claimant, claimant2, typedData }
  }

  it('should deploy the contract with the right params', async function () {
    const { badgesContract } = await loadFixture(deployContractFixture)

    const deployedContractName = await badgesContract.name()
    const deployedSymbolName = await badgesContract.symbol()
    expect(deployedContractName).to.equal(name)
    expect(deployedSymbolName).to.equal(symbol)

    const provider = waffle.provider
    const network = await provider.getNetwork()
    const deployedToChainId = network.chainId
    expect(deployedToChainId).to.equal(chainId)
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

  it('should fail to mintWithAuthorizedBadge when trying to claim with a wallet address that doesnt match the signature', async () => {
    const { badgesContract, typedData, issuer, claimant } = await loadFixture(deployContractFixture)
    const signature = await issuer._signTypedData(typedData.domain, typedData.types, typedData.value)
    const { compact } = splitSignature(signature)
    const randomWallet = Wallet.createRandom()

    await expect(
      badgesContract.connect(claimant).mintAuthorizedBadge(randomWallet.address, typedData.value.tokenURI, compact)
    ).to.be.revertedWith('mintAuthorizedBadge: badge minting failed')
  })

  it('should fail to mintWithAuthorizedBadge when signature is created with an incorrect address', async () => {
    const { badgesContract, typedData, issuer, claimant } = await loadFixture(deployContractFixture)
    const randomWallet = Wallet.createRandom()

    // genera
    typedData.value.passive = randomWallet.address
    const signature = await issuer._signTypedData(typedData.domain, typedData.types, typedData.value)
    const { compact } = splitSignature(signature)

    await expect(
      badgesContract.connect(claimant).mintAuthorizedBadge(typedData.value.passive, typedData.value.tokenURI, compact)
    ).to.be.revertedWith('mintAuthorizedBadge: badge minting failed')
  })

  it('should fail to mintWithAuthorizedBadge when using incorrect token uri', async () => {
    const { badgesContract, typedData, issuer, claimant } = await loadFixture(deployContractFixture)
    const signature = await issuer._signTypedData(typedData.domain, typedData.types, typedData.value)
    const { compact } = splitSignature(signature)

    await expect(
      badgesContract.connect(claimant).mintAuthorizedBadge(typedData.value.passive, incorrectUri, compact)
    ).to.be.revertedWith('mintAuthorizedBadge: spec is not registered')
  })

  it('should fail to mintWithAuthorizedBadge when using invalid signature', async () => {
    const { badgesContract, typedData, claimant } = await loadFixture(deployContractFixture)
    const sig = { compact: 'junk conpact value' }
    const sigAsBytes = ethers.utils.hexlify(ethers.utils.toUtf8Bytes(JSON.stringify(sig)))

    await expect(
      badgesContract
        .connect(claimant)
        .mintAuthorizedBadge(typedData.value.passive, typedData.value.tokenURI, sigAsBytes)
    ).to.be.revertedWith('mintAuthorizedBadge: badge minting failed')
  })

  it('should fail to mintWithAuthorizedBadge when using unauthorized claimant', async () => {
    const { badgesContract, typedData, issuer, claimant2 } = await loadFixture(deployContractFixture)
    const signature = await issuer._signTypedData(typedData.domain, typedData.types, typedData.value)
    const { compact } = splitSignature(signature)

    await expect(
      badgesContract.connect(claimant2).mintAuthorizedBadge(typedData.value.passive, typedData.value.tokenURI, compact)
    ).to.be.revertedWith('mintAuthorizedBadge: badge minting failed')
  })

  it('should successfully mintAuthorizedBadge', async function () {
    const { badgesContract, issuer, claimant, typedData } = await deployContractFixture()

    const signature = await issuer._signTypedData(typedData.domain, typedData.types, typedData.value)
    const { compact } = splitSignature(signature)

    const txn = await badgesContract
      .connect(claimant)
      .mintAuthorizedBadge(typedData.value.passive, typedData.value.tokenURI, compact)
    const receipt = await txn.wait()
    expect(receipt.status).to.equal(1)

    const tokenHash = badgesContract.getHash(typedData.value.active, typedData.value.passive, typedData.value.tokenURI)
    const tokenId = await badgesContract.getTokenIdFromHash(tokenHash)
    const ownerOfMintedToken = await badgesContract.ownerOf(tokenId)
    expect(ownerOfMintedToken).to.equal(claimant.address)

    const balanceOfClaimant = await badgesContract.balanceOf(claimant.address)
    expect(balanceOfClaimant).to.equal(1)

    const uriOfToken = await badgesContract.tokenURI(tokenId)
    expect(uriOfToken).to.equal(typedData.value.tokenURI)
  })
})
