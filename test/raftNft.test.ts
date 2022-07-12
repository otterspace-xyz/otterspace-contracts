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

    before(async () => {
        const RaftNFT = await ethers.getContractFactory('RaftNFT')
        raftNFTContract = await RaftNFT.deploy()
        await raftNFTContract.deployed()
    })

    it('should deploy the contract with the right params', async function () {
        const deployedContractName = await raftNFTContract.name()
        const deployedSymbolName = await raftNFTContract.symbol()
        expect(deployedContractName).to.equal(name)
        expect(deployedSymbolName).to.equal(symbol)

        const provider = waffle.provider
        const network = await provider.getNetwork()
        const deployedToChainId = network.chainId
        expect(deployedToChainId).to.equal(chainId)
    })

    it('should mint a token', async function () {
        const tokenId = 1
        const [contractOwner, tokenRecipient] = await ethers.getSigners()

        const tokenRecipientAddress = tokenRecipient.address
        const tokenRecipientBalance = await raftNFTContract.balanceOf(tokenRecipientAddress)
        console.log('🚀 ~ tokenRecipientBalance', tokenRecipientBalance)

        await raftNFTContract.createToken(tokenRecipientAddress, tokenURI)
        const tokenRecipientBalanceAfter = await raftNFTContract.balanceOf(tokenRecipientAddress)
        console.log('🚀 ~ tokenRecipientBalanceAfter', tokenRecipientBalanceAfter)

        expect(tokenRecipientBalanceAfter).to.equal(tokenRecipientBalance.add(1))
    })
})
