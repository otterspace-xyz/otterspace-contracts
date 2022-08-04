import { expect } from 'chai'
import { ethers, upgrades } from 'hardhat'
import { Raft } from '../typechain-types'
import { waffle } from 'hardhat'
import type { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
let deployed: any
let raftProxy: Raft
const name = 'Raft'
const symbol = 'RAFT'
const chainId = 31337
const tokenURI = 'blah'
const errNotOwner = 'Ownable: caller is not the owner'
const errNonExitentTokenToSet = '_setTokenURI: URI set of nonexistent token'
const raftTokenUri = 'someUri'

const setup = async () => {
  await deployContractFixture()
}

beforeEach(setup)

const deployContractFixture = async () => {
  const [owner, addr1, addr2] = await ethers.getSigners()

  const raft = await ethers.getContractFactory('Raft')
  const raftProxy = await upgrades.deployProxy(raft, [owner.address, 'Raft', 'RAFT'], {
    kind: 'uups',
  })
  const txn = await raftProxy.mint(owner.address, raftTokenUri)
  const txReceipt = await txn.wait()
  expect(txReceipt.status).equal(1)

  const [transferEvent] = txReceipt.events!
  const { tokenId: rawTokenId } = transferEvent.args!
  const raftTokenId = ethers.BigNumber.from(rawTokenId).toNumber()
  expect(raftTokenId).gt(0)

  const raftTokenOwner = await raftProxy.ownerOf(raftTokenId)
  expect(raftTokenOwner).equal(owner.address)

  deployed = { raftProxy, raftTokenId, owner, addr1, addr2 }
}

describe('Raft Upgrades', async function () {
  it.only('Should upgrade then instantiate new variable right after', async () => {
    const { raftProxy } = deployed

    const raftV2 = await ethers.getContractFactory('RaftV2')
    const upgradedV2Contract = await upgrades.upgradeProxy(raftProxy.address, raftV2)
    await upgradedV2Contract.deployed()
    await upgradedV2Contract.setNewVar()
    const newVar = await upgradedV2Contract.myNewVar()
    expect(newVar).equal(9)
    await expect(upgradedV2Contract.setNewVar()).to.be.revertedWith('Var is already set')
  })
})

describe('Raft', async function () {
  it('should deploy the contract with the right params', async function () {
    const { raftProxy, owner } = deployed
    const deployedContractName = await raftProxy.name()
    const deployedSymbolName = await raftProxy.symbol()
    const deployedContractOwner = await raftProxy.owner()
    expect(deployedContractOwner).to.equal(owner.address)
    expect(deployedContractName).to.equal(name)
    expect(deployedSymbolName).to.equal(symbol)

    const isPaused = await raftProxy.paused()
    expect(isPaused).to.equal(true)

    const provider = waffle.provider
    const network = await provider.getNetwork()
    const deployedToChainId = network.chainId
    expect(deployedToChainId).to.equal(chainId)
  })

  it('should allow owner to mint when minting is paused', async function () {
    const { raftProxy, addr1 } = deployed
    const recipientAddress = addr1.address
    const recipientBalance = await raftProxy.balanceOf(recipientAddress)

    const isPaused = await raftProxy.paused()
    expect(isPaused).to.equal(true)

    await raftProxy.mint(recipientAddress, tokenURI)
    const recipientBalanceAfter = await raftProxy.balanceOf(recipientAddress)
    expect(recipientBalanceAfter).to.equal(recipientBalance.add(1))
  })

  it('should prevent non-owner from minting when minting is paused', async function () {
    const { raftProxy, addr1 } = deployed
    const isPaused = await raftProxy.paused()
    expect(isPaused).to.equal(true)

    await expect(raftProxy.connect(addr1).mint(addr1.address, tokenURI)).to.be.revertedWith(
      'mint: unauthorized to mint'
    )
  })

  it('should should allow non-owner to mint when minting is unpaused', async function () {
    const { raftProxy, addr1 } = deployed

    await raftProxy.unpause()
    const isPaused = await raftProxy.paused()
    expect(isPaused).to.equal(false)

    await raftProxy.connect(addr1).mint(addr1.address, tokenURI)
    expect(await raftProxy.balanceOf(addr1.address)).to.equal(1)
  })

  it('should fetch then tokenURI after minting', async function () {
    const { raftProxy, addr1 } = deployed

    const tx = await raftProxy.mint(addr1.address, tokenURI)
    const txReceipt = await tx.wait()
    const [transferEvent] = txReceipt.events!
    const { tokenId: rawTokenId } = transferEvent.args!
    const tokenId = ethers.BigNumber.from(rawTokenId).toNumber()

    const fetchedTokenURI = await raftProxy.tokenURI(tokenId)
    expect(tokenURI).to.equal(fetchedTokenURI)
  })

  it('should not allow non-owner to call pause', async function () {
    const { raftProxy, addr1 } = deployed
    await expect(raftProxy.connect(addr1).pause()).to.be.revertedWith('Ownable: caller is not the owner')
  })

  it('should mint 2 tokens, query the balance, then retrieve the correct tokenIds', async function () {
    const { raftProxy, addr1 } = deployed

    const tx = await raftProxy.mint(addr1.address, tokenURI)
    const txReceipt = await tx.wait()

    const tx2 = await raftProxy.mint(addr1.address, tokenURI)
    const txReceipt2 = await tx2.wait()

    const balanceOfOwner = await raftProxy.balanceOf(addr1.address)
    expect(balanceOfOwner).to.equal(2)

    const token1 = await raftProxy.tokenOfOwnerByIndex(addr1.address, 0)
    const parsedTokenId1 = ethers.BigNumber.from(txReceipt.events![0].args!.tokenId).toNumber()
    expect(token1).to.equal(parsedTokenId1)

    const token2 = await raftProxy.tokenOfOwnerByIndex(addr1.address, 1)
    const parsedTokenId2 = ethers.BigNumber.from(txReceipt2.events![0].args!.tokenId).toNumber()
    expect(token2).to.equal(parsedTokenId2)
  })

  it('should successful set token uri when called by owner', async () => {
    const { raftProxy, owner, addr1 } = deployed

    let tx = await raftProxy.mint(addr1.address, tokenURI)
    let txReceipt = await tx.wait()
    const [transferEvent] = txReceipt.events!
    const { tokenId: rawTokenId } = transferEvent.args!
    const tokenId = ethers.BigNumber.from(rawTokenId).toNumber()

    const newTokenUri: string = 'https://new-token-uri.com'
    tx = await raftProxy.connect(owner).setTokenURI(tokenId, newTokenUri)
    tx.wait()

    const actualUpdatedTokenUri = await raftProxy.tokenURI(tokenId)
    expect(actualUpdatedTokenUri).to.equal(newTokenUri)
  })

  it('should fail to set token uri when called by a non-owner', async () => {
    const { raftProxy, addr1 } = deployed

    const tx = await raftProxy.mint(addr1.address, tokenURI)
    const txReceipt = await tx.wait()
    const [transferEvent] = txReceipt.events!
    const { tokenId: rawTokenId } = transferEvent.args!
    const tokenId = ethers.BigNumber.from(rawTokenId).toNumber()

    const newTokenUri: string = 'https://new-token-uri.com'
    await expect(raftProxy.connect(addr1).setTokenURI(tokenId, newTokenUri)).to.be.revertedWith(errNotOwner)
  })

  it('should fail to set token uri for a non-existent token id', async () => {
    const { raftProxy, owner } = deployed

    const nonExistentTokenId = 1010101
    const newTokenUri: string = 'https://new-token-uri.com'
    await expect(raftProxy.connect(owner).setTokenURI(nonExistentTokenId, newTokenUri)).to.be.revertedWith(
      errNonExitentTokenToSet
    )
  })
})
