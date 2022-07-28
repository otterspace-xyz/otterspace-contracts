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
  const errNotOwner = 'Ownable: caller is not the owner'
  const errNonExitentTokenToSet = '_setTokenURI: URI set of nonexistent token'

  async function deployContractFixture() {
    const raft = await ethers.getContractFactory('Raft')
    const [owner, signer1] = await ethers.getSigners()
    const raftContract = await raft.deploy(owner.address, name, symbol)
    await raftContract.deployed()
    return { raft, raftContract, owner, signer1 }
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
    const { raftContract, signer1 } = await loadFixture(deployContractFixture)
    const recipientAddress = signer1.address
    const recipientBalance = await raftContract.balanceOf(recipientAddress)

    const isPaused = await raftContract.paused()
    expect(isPaused).to.equal(true)

    await raftContract.mint(recipientAddress, tokenURI)
    const recipientBalanceAfter = await raftContract.balanceOf(recipientAddress)
    expect(recipientBalanceAfter).to.equal(recipientBalance.add(1))
  })

  it('should prevent non-owner from minting when minting is paused', async function () {
    const { raftContract, signer1 } = await loadFixture(deployContractFixture)
    const isPaused = await raftContract.paused()
    expect(isPaused).to.equal(true)

    await expect(raftContract.connect(signer1).mint(signer1.address, tokenURI)).to.be.revertedWith(
      'mint: unauthorized to mint'
    )
  })

  it('should should allow non-owner to mint when minting is unpaused', async function () {
    const { raftContract, signer1 } = await loadFixture(deployContractFixture)

    await raftContract.unpause()
    const isPaused = await raftContract.paused()
    expect(isPaused).to.equal(false)

    await raftContract.connect(signer1).mint(signer1.address, tokenURI)
    expect(await raftContract.balanceOf(signer1.address)).to.equal(1)
  })

  it('should fetch then tokenURI after minting', async function () {
    const { raftContract, signer1 } = await loadFixture(deployContractFixture)

    const tx = await raftContract.mint(signer1.address, tokenURI)
    const txReceipt = await tx.wait()
    const [transferEvent] = txReceipt.events!
    const { tokenId: rawTokenId } = transferEvent.args!
    const tokenId = ethers.BigNumber.from(rawTokenId).toNumber()

    const fetchedTokenURI = await raftContract.tokenURI(tokenId)
    expect(tokenURI).to.equal(fetchedTokenURI)
  })

  it('should not allow non-owner to call pause', async function () {
    const { raftContract, signer1 } = await loadFixture(deployContractFixture)
    await expect(raftContract.connect(signer1).pause()).to.be.revertedWith('Ownable: caller is not the owner')
  })

  it('should mint 2 tokens, query the balance, then retrieve the correct tokenIds', async function () {
    const { raftContract, signer1 } = await loadFixture(deployContractFixture)

    const tx = await raftContract.mint(signer1.address, tokenURI)
    const txReceipt = await tx.wait()

    const tx2 = await raftContract.mint(signer1.address, tokenURI)
    const txReceipt2 = await tx2.wait()

    const balanceOfOwner = await raftContract.balanceOf(signer1.address)
    expect(balanceOfOwner).to.equal(2)

    const token1 = await raftContract.tokenOfOwnerByIndex(signer1.address, 0)
    const parsedTokenId1 = ethers.BigNumber.from(txReceipt.events![0].args!.tokenId).toNumber()
    expect(token1).to.equal(parsedTokenId1)

    const token2 = await raftContract.tokenOfOwnerByIndex(signer1.address, 1)
    const parsedTokenId2 = ethers.BigNumber.from(txReceipt2.events![0].args!.tokenId).toNumber()
    expect(token2).to.equal(parsedTokenId2)
  })

  it('should successful set token uri when called by owner', async () => {
    const { raftContract, owner, signer1 } = await loadFixture(deployContractFixture)

    let tx = await raftContract.mint(signer1.address, tokenURI)
    let txReceipt = await tx.wait()
    const [transferEvent] = txReceipt.events!
    const { tokenId: rawTokenId } = transferEvent.args!
    const tokenId = ethers.BigNumber.from(rawTokenId).toNumber()

    const newTokenUri: string = "https://new-token-uri.com"
    tx = await raftContract.connect(owner).setTokenURI(tokenId, newTokenUri)
    tx.wait()

    const actualUpdatedTokenUri = await raftContract.tokenURI(tokenId)
    expect(actualUpdatedTokenUri).to.equal(newTokenUri)
  });

  it('should fail to set token uri when called by a non-owner', async () => {
    const { raftContract, signer1 } = await loadFixture(deployContractFixture)

    const tx = await raftContract.mint(signer1.address, tokenURI)
    const txReceipt = await tx.wait()
    const [transferEvent] = txReceipt.events!
    const { tokenId: rawTokenId } = transferEvent.args!
    const tokenId = ethers.BigNumber.from(rawTokenId).toNumber()

    const newTokenUri: string = "https://new-token-uri.com"
    await expect(raftContract.connect(signer1).setTokenURI(tokenId, newTokenUri)).to.be.revertedWith(errNotOwner)
  });

  it('should fail to set token uri for a non-existent token id', async () => {
    const { raftContract, owner } = await loadFixture(deployContractFixture)

    const nonExistentTokenId = 1010101
    const newTokenUri: string = "https://new-token-uri.com"
    await expect(raftContract.connect(owner).setTokenURI(nonExistentTokenId, newTokenUri)).to.be.revertedWith(errNonExitentTokenToSet)
  });
})
