import { expect } from 'chai'
import { ethers } from 'hardhat'

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { waffle } from 'hardhat'
import { splitSignature, _TypedDataEncoder } from 'ethers/lib/utils'
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers'
import { Wallet } from 'ethers'
import { BadgesTest__factory } from '../typechain-types/factories/src/Badges.t.sol'

describe('BadgesController', async function () {
  const name = 'Otter'
  const symbol = 'OTTR'
  const version = '1'
  const chainId = 31337
  const specUri = 'blah'
  const tokenURI = 'blah'

  async function deployContractFixture() {
    const [owner, issuer, claimant, badActor] = await ethers.getSigners()
    const badges = await ethers.getContractFactory('Badges')
    const badgesController = await ethers.getContractFactory('BadgesController')
    const raft = await ethers.getContractFactory('Raft')

    const badgesContract = await badges.deploy(name, symbol, version)
    const raftContract = await raft.deploy(owner.address, name, symbol)

    await badgesContract.deployed()
    await raftContract.deployed()

    const unpauseTx = await raftContract.unpause()
    await unpauseTx.wait()
    // mint the raft token to the issuer
    const tx = await raftContract.mint(issuer.address, specUri)
    const txReceipt = await tx.wait()
    const [transferEvent] = txReceipt.events!
    const { tokenId: rawTokenId } = transferEvent.args!
    const raftTokenId = ethers.BigNumber.from(rawTokenId).toNumber()

    const badgesControllerContract = await badgesController.deploy(
      badgesContract.address,
      raftContract.address,
      name,
      version
    )
    await badgesControllerContract.deployed()

    const badgesControllerTypedData = {
      domain: {
        name: name,
        version: version,
        chainId,
        verifyingContract: badgesControllerContract.address,
      },
      types: {
        CreateSpecPermit: [
          { name: 'to', type: 'address' },
          { name: 'raftTokenId', type: 'uint256' },
        ],
      },
      value: {
        to: claimant.address,
        raftTokenId,
      },
    }

    const badgesTypedData = {
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
        tokenURI,
      },
    }

    return {
      badges,
      badgesContract,
      badgesControllerContract,
      owner,
      issuer,
      claimant,
      badActor,
      badgesControllerTypedData,
      raftContract,
      badgesTypedData,
      raftTokenId,
    }
  }

  it('should match off-chain hash to on-chain hash', async () => {
    const { badgesControllerContract, badgesControllerTypedData } = await loadFixture(deployContractFixture)
    const provider = waffle.provider
    const network = await provider.getNetwork()
    const deployedToChainId = network.chainId
    expect(deployedToChainId).to.equal(chainId)

    const offChainHash = _TypedDataEncoder.hash(
      badgesControllerTypedData.domain,
      badgesControllerTypedData.types,
      badgesControllerTypedData.value
    )
    const onChainHash = await badgesControllerContract.getCreateSpecHash(
      badgesControllerTypedData.value.to,
      badgesControllerTypedData.value.raftTokenId
    )

    expect(offChainHash).to.equal(onChainHash)
  })

  it('should registerSpecWithSignature when given a correct signature', async () => {
    const { badgesControllerContract, badgesControllerTypedData, issuer, claimant, raftContract } = await loadFixture(
      deployContractFixture
    )
    const signature = await issuer._signTypedData(
      badgesControllerTypedData.domain,
      badgesControllerTypedData.types,
      badgesControllerTypedData.value
    )
    const { compact } = splitSignature(signature)
    const isPaused = await raftContract.paused()

    expect(isPaused).to.equal(false)

    const txn = await badgesControllerContract
      .connect(claimant)
      .registerSpecWithSignature(specUri, badgesControllerTypedData.value.raftTokenId, compact, false)

    const receipt = await txn.wait()

    expect(receipt.status).to.equal(1)
    await expect(
      badgesControllerContract
        .connect(claimant)
        .registerSpecWithSignature(specUri, badgesControllerTypedData.value.raftTokenId, compact, false)
    ).to.be.revertedWith('Spec already registered')
  })

  it('should fail to register badge spec when using invalid signature', async () => {
    const { badgesControllerContract, badgesControllerTypedData, issuer, claimant, raftContract } = await loadFixture(
      deployContractFixture
    )
    const sig = { compact: 'random string' }
    const sigAsBytes = ethers.utils.hexlify(ethers.utils.toUtf8Bytes(JSON.stringify(sig)))

    const isPaused = await raftContract.paused()

    const randomWallet = Wallet.createRandom()

    expect(isPaused).to.equal(false)

    await expect(
      badgesControllerContract
        .connect(claimant)
        .registerSpecWithSignature(specUri, badgesControllerTypedData.value.raftTokenId, sigAsBytes, false)
    ).to.be.revertedWith('registerSpec: invalid signature')
  })

  it('should fail to register badge spec to an unauthorized claimant', async () => {
    const { badgesControllerContract, badgesControllerTypedData, issuer, claimant, raftContract, badActor } =
      await loadFixture(deployContractFixture)
    const signature = await issuer._signTypedData(
      badgesControllerTypedData.domain,
      badgesControllerTypedData.types,
      badgesControllerTypedData.value
    )
    const { compact } = splitSignature(signature)

    await expect(
      badgesControllerContract
        .connect(badActor)
        .registerSpecWithSignature(specUri, badgesControllerTypedData.value.raftTokenId, compact, false)
    ).to.be.revertedWith('registerSpec: invalid signature')
  })

  it('should registerSpec when given a correct signature', async () => {
    const { badgesContract, badgesControllerContract, raftTokenId, badgesTypedData, issuer, claimant } =
      await loadFixture(deployContractFixture)
    const signature = await issuer._signTypedData(badgesTypedData.domain, badgesTypedData.types, badgesTypedData.value)
    const { compact } = splitSignature(signature)

    const txn = await badgesContract
      .connect(claimant)
      .take(badgesTypedData.value.passive, badgesTypedData.value.tokenURI, compact)
    const receipt = await txn.wait()

    expect(receipt.status).to.equal(1)

    const tokenHash = badgesContract.getHash(
      badgesTypedData.value.active,
      badgesTypedData.value.passive,
      badgesTypedData.value.tokenURI
    )
    const tokenId = await badgesContract.getTokenIdFromHash(tokenHash)

    const ownerOfMintedToken = await badgesContract.ownerOf(tokenId)
    console.log('🚀 ~ it ~ ownerOfMintedToken', ownerOfMintedToken)

    expect(ownerOfMintedToken).to.equal(claimant.address)

    const balanceOfClaimant = await badgesContract.balanceOf(claimant.address)

    expect(balanceOfClaimant).to.equal(1)
    const registerTx = await badgesControllerContract
      .connect(claimant)
      .registerSpec(tokenId, raftTokenId, specUri, false)
    await registerTx.wait()

    const checkExistenceReceipt = await badgesControllerContract.checkIfSpecExists(specUri)
    console.log('🚀 ~ it ~ checkExistenceReceipt', checkExistenceReceipt)
  })
})
