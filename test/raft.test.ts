import { expect } from 'chai'
import { ethers } from 'hardhat'
import { Raft } from '../typechain-types'
import { waffle } from 'hardhat'
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers'

describe('Raft', async function () {
  let raftContract: Raft
  const name = 'Raft'
  const symbol = 'RAFT'
  const chainId = 31337
  const tokenURI = 'blah'

  async function deployContractFixture() {
    const raft = await ethers.getContractFactory('Raft')
    const [owner, addr1] = await ethers.getSigners()
    const raftContract = await raft.deploy(owner.address, name, symbol)
    await raftContract.deployed()
    return { raft, raftContract, owner, addr1 }
  }

  it('should deploy the contract with the right params', async function () {
    const { raftContract, owner } = await loadFixture(deployContractFixture)
    const deployedContractName = await raftContract.name()
    const deployedSymbolName = await raftContract.symbol()
    const deployedContractOwner = await raftContract.owner()
    expect(deployedContractOwner).to.equal(owner.address)
    expect(deployedContractName).to.equal(name)
    expect(deployedSymbolName).to.equal(symbol)

    const isPaused = await raftContract.paused()
    expect(isPaused).to.equal(true)

    const provider = waffle.provider
    const network = await provider.getNetwork()
    const deployedToChainId = network.chainId
    expect(deployedToChainId).to.equal(chainId)
  })

  it('should allow owner to mint when minting is paused', async function () {
    const { raftContract, addr1 } = await loadFixture(deployContractFixture)
    const recipientAddress = addr1.address
    const recipientBalance = await raftContract.balanceOf(recipientAddress)

    const isPaused = await raftContract.paused()
    expect(isPaused).to.equal(true)

    await raftContract.mint(recipientAddress, tokenURI)
    const recipientBalanceAfter = await raftContract.balanceOf(recipientAddress)
    expect(recipientBalanceAfter).to.equal(recipientBalance.add(1))
  })

  it('should prevent non-owner from minting when minting is paused', async function () {
    const { raftContract, addr1 } = await loadFixture(deployContractFixture)
    const isPaused = await raftContract.paused()
    expect(isPaused).to.equal(true)

    await expect(raftContract.connect(addr1).mint(addr1.address, tokenURI)).to.be.revertedWith(
      'mint: unauthorized to mint'
    )
  })

  it('should should allow non-owner to mint when minting is unpaused', async function () {
    const { raftContract, addr1 } = await loadFixture(deployContractFixture)

    await raftContract.unpause()
    const isPaused = await raftContract.paused()
    expect(isPaused).to.equal(false)

    await raftContract.connect(addr1).mint(addr1.address, tokenURI)
    expect(await raftContract.balanceOf(addr1.address)).to.equal(1)
  })

  it('should fetch then tokenURI after minting', async function () {
    const { raftContract, addr1 } = await loadFixture(deployContractFixture)

    const tx = await raftContract.mint(addr1.address, tokenURI)
    const txReceipt = await tx.wait()
    const [transferEvent] = txReceipt.events!
    const { tokenId: rawTokenId } = transferEvent.args!
    const tokenId = ethers.BigNumber.from(rawTokenId).toNumber()

    const fetchedTokenURI = await raftContract.tokenURI(tokenId)
    expect(tokenURI).to.equal(fetchedTokenURI)
  })

  it('should not allow non-owner to call pause', async function () {
    const { raftContract, addr1 } = await loadFixture(deployContractFixture)
    await expect(raftContract.connect(addr1).pause()).to.be.revertedWith('Ownable: caller is not the owner')
  })
})
