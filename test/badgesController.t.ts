import { expect } from 'chai'
import { ethers } from 'hardhat'

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { waffle } from 'hardhat'
import { splitSignature, _TypedDataEncoder } from 'ethers/lib/utils'
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers'

describe('Badges', async function () {
  const name = 'Otter'
  const symbol = 'OTTR'
  const version = '1'
  const chainId = 31337
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

    const tx = await raftContract.mint(owner.address, 'someUri')
    const txReceipt = await tx.wait()
    const [transferEvent] = txReceipt.events!
    const { tokenId: rawTokenId } = transferEvent.args!
    const tokenId = ethers.BigNumber.from(rawTokenId).toNumber()

    const badgesControllerContract = await badgesController.deploy(
      badgesContract.address,
      raftContract.address,
      'badges controller',
      'v1'
    )
    await badgesControllerContract.deployed()

    const typedData = {
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
        raftTokenId: tokenId,
      },
    }
    return { badges, badgesContract, badgesControllerContract, owner, issuer, claimant, badActor, typedData }
  }

  it('should register a spec with signature when given a correct signature', async () => {
    const { badgesControllerContract, typedData, issuer, claimant } = await loadFixture(deployContractFixture)

    const signature = await issuer._signTypedData(typedData.domain, typedData.types, typedData.value)
    const { compact } = splitSignature(signature)

    const txn = await badgesControllerContract
      .connect(claimant)
      .registerSpecWithSignature('some uri', typedData.value.raftTokenId, compact, false)
    const receipt = await txn.wait()

    expect(receipt.status).to.equal(1)
    await expect(
      badgesControllerContract
        .connect(claimant)
        .registerSpecWithSignature('some uri', typedData.value.raftTokenId, compact, false)
    ).to.be.revertedWith('Spec already registered')
  })
})
