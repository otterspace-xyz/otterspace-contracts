import { expect } from 'chai'
import { ethers } from 'hardhat'
import { Raft } from '../typechain-types'
import { Wallet } from 'ethers'
import { waffle } from 'hardhat'

describe('Raft', async function () {
    let raftContract: Raft
    const name = 'Raft NFT'
    const symbol = 'RAFT'
    const chainId = 31337
    const tokenURI = 'blah'

    it('should deploy the contract with the right params', async function () {
        const Raft = await ethers.getContractFactory('Raft')
        const [owner] = await ethers.getSigners()
        const raftContract = await Raft.deploy(owner.address, name, symbol)
        await raftContract.deployed()
        const deployedContractName = await raftContract.name()
        const deployedSymbolName = await raftContract.symbol()
        expect(deployedContractName).to.equal(name)
        expect(deployedSymbolName).to.equal(symbol)

        const provider = waffle.provider
        const network = await provider.getNetwork()
        const deployedToChainId = network.chainId
        expect(deployedToChainId).to.equal(chainId)
    })

    it('owner should be able to mint an NFT when minting is pause', async function () {
        const Raft = await ethers.getContractFactory('Raft')
        const [owner] = await ethers.getSigners()
        const raftContract = await Raft.deploy(owner.address, name, symbol)
        await raftContract.deployed()

        const [, recipient] = await ethers.getSigners()

        const recipientAddress = recipient.address
        const recipientBalance = await raftContract.balanceOf(recipientAddress)

        await raftContract.mint(recipientAddress, tokenURI)
        const recipientBalanceAfter = await raftContract.balanceOf(recipientAddress)

        expect(recipientBalanceAfter).to.equal(recipientBalance.add(1))
    })

    it('should prevent non-owner from minting when minting is paused', async function () {
        const Raft = await ethers.getContractFactory('Raft')
        const [owner, nonOwner] = await ethers.getSigners()
        const raftContract = await Raft.deploy(owner.address, name, symbol)
        await raftContract.deployed()
        const nonOwnerAddress = nonOwner.address
        const tx = await raftContract.mint(nonOwnerAddress, tokenURI)
        const balance = await raftContract.balanceOf(nonOwnerAddress)
        console.log('🚀 ~ balance', balance)

        expect(tx).to.be.revertedWith('mint: unauthorized to mint')
    })

    // should fetch then tokenURI after minting
    it('should fetch then tokenURI after minting', async function () {
        const Raft = await ethers.getContractFactory('Raft')
        const [owner] = await ethers.getSigners()
        const raftContract = await Raft.deploy(owner.address, name, symbol)
        await raftContract.deployed()
        const [, recipient] = await ethers.getSigners()
        const recipientAddress = recipient.address
        const tokenURI = 'blah'
        await raftContract.mint(recipientAddress, tokenURI)
        const fetchedTokenURI = await raftContract.tokenURI(recipientAddress)
        expect(fetchedTokenURI).to.equal(tokenURI)
    })

    // should not allow minting when non-owner calls contract when minting is paused

    // should allow owner to mint when minting is paused

    // should not allow non-owner to call pause
    it('should not allow non-owner to call pause', async function () {
        const Raft = await ethers.getContractFactory('Raft')
        const [, nonOwner] = await ethers.getSigners()
        const nonOwnerAddress = nonOwner.address
        const raftContract = await Raft.deploy(nonOwnerAddress, name, symbol)
        await raftContract.deployed()
        const tx = await raftContract.pause()
        expect(tx).to.be.revertedWith('pause: unauthorized to pause')
    })
})
