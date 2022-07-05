import { expect } from 'chai'
import { ethers } from 'hardhat'
import { Badges } from '../typechain-types'
import { Wallet } from 'ethers'
import { waffle } from 'hardhat'

describe('Badges', function () {
    let badgesContract: Badges

    beforeEach(async () => {
        const Badges = await ethers.getContractFactory('Badges')
        badgesContract = await Badges.deploy('Otter', 'OTTR', '1.0.0')
    })

    it('Should return the name of the badge', async function () {
        await badgesContract.deployed()
        expect(await badgesContract.name()).to.equal('Otter')
    })

    it("should revert with message 'mintWithPermission: invalid signature', when given a bad signature", async () => {
        await badgesContract.deployed()
        const provider = waffle.provider
        const sig = {
            v: 28,
            r: 'junk r value',
            s: 'junk s value',
            compact: 'jumk conpact value',
            yParityAndS: 'junk parity value',
            _vs: 'blah',
        }
        const sigAsBytes = ethers.utils.hexlify(ethers.utils.toUtf8Bytes(JSON.stringify(sig)))
        const issuerWallet = new Wallet('5f9a26937a48e1d6659c13f2115159886318545a405b33e9658e8188609cd80b', provider)
        await expect(
            badgesContract.mintWithPermission(issuerWallet.address, 'https://someURI.com', sigAsBytes)
        ).to.be.revertedWith('mintWithPermission: invalid signature')
    })
})

// mint with authorized signatures succeeds

// payloads of off-chain and on-chain events are the same
