import { expect } from 'chai'
import { ethers } from 'hardhat'
import { RaftNFT } from '../typechain-types'
import { Wallet } from 'ethers'
import { waffle } from 'hardhat'

describe('RaftNFT', async function () {
    let raftNFTContract: RaftNFT
    const name = 'Raft NFT'
    const symbol = 'RAFT'
    const chainId = 31337
    const tokenURI = 'blah'

    it('should deploy the contract with the right params', async function () {
        const RaftNFT = await ethers.getContractFactory('RaftNFT')
        const [owner] = await ethers.getSigners()
        const raftNFTContract = await RaftNFT.deploy(owner.address, name, symbol)
        await raftNFTContract.deployed()
        const deployedContractName = await raftNFTContract.name()
        const deployedSymbolName = await raftNFTContract.symbol()
        expect(deployedContractName).to.equal(name)
        expect(deployedSymbolName).to.equal(symbol)

        const provider = waffle.provider
        const network = await provider.getNetwork()
        const deployedToChainId = network.chainId
        expect(deployedToChainId).to.equal(chainId)
    })

    it('owner should be able to mint an NFT when minting is paused', async function () {
        const RaftNFT = await ethers.getContractFactory('RaftNFT')
        const [owner] = await ethers.getSigners()
        const raftNFTContract = await RaftNFT.deploy(owner.address, name, symbol)
        await raftNFTContract.deployed()

        const [, recipient] = await ethers.getSigners()

        const recipientAddress = recipient.address
        const recipientBalance = await raftNFTContract.balanceOf(recipientAddress)

        await raftNFTContract.mint(recipientAddress, tokenURI)
        const recipientBalanceAfter = await raftNFTContract.balanceOf(recipientAddress)

        expect(recipientBalanceAfter).to.equal(recipientBalance.add(1))
    })

    it('should prevent non-owner from minting when minting is paused', async function () {
        const RaftNFT = await ethers.getContractFactory('RaftNFT')
        const [, nonOwner] = await ethers.getSigners()
        const nonOwnerAddress = nonOwner.address
        const raftContract = await RaftNFT.deploy(nonOwnerAddress, name, symbol)
        await raftContract.deployed()
        const tx = await raftContract.mint(nonOwnerAddress, tokenURI)
        const balance = await raftContract.balanceOf(nonOwnerAddress)
        console.log('🚀 ~ balance', balance)

        expect(tx).to.be.revertedWith('mint: unauthorized to mint')
    })

    // should not allow minting when non-owner calls contract when minting is paused

    // should allow owner to mint when minting is paused

    // should not allow non-owner to call pause
    it('should not allow non-owner to call pause', async function () {
        const [, recipient] = await ethers.getSigners()

        await expect(raftNFTContract.pause()).to.be.revertedWith('pause: unauthorized to pause')
    })
})
