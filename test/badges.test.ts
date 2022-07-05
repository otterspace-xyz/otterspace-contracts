import { expect } from 'chai'
import { ethers } from 'hardhat'

describe('Badges', function () {
    it('Should return then name of the badge', async function () {
        const Badges = await ethers.getContractFactory('Badges')
        const badges = await Badges.deploy('Otter', 'OTTR', '1.0.0')
        await badges.deployed()
        expect(await badges.name()).to.equal('Otter')
    })
})

// deploy the contract

// pass contract arguments correctly

// mint withn unauthorized signatures fails

// mint with authorized signatures succeeds

// payloads of off-chain and on-chain events are the same
