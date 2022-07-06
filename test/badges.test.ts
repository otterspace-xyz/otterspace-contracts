import { expect } from 'chai'
import { ethers } from 'hardhat'
import { Badges } from '../typechain-types'
import { Wallet } from 'ethers'
import { waffle } from 'hardhat'
import signVoucher from './utils/sig-checker'
import { splitSignature, _TypedDataEncoder } from 'ethers/lib/utils'
import { assert } from 'console'

describe('Badges', function () {
    let badgesContract: Badges
    const name = 'Otter'
    const symbol = 'OTTR'
    const version = '1'
    beforeEach(async () => {
        const Badges = await ethers.getContractFactory('Badges')
        // needs to match my domain object below
        badgesContract = await Badges.deploy(name, symbol, version)
    })

    // it('Should return the name of the badge', async function () {
    //     await badgesContract.deployed()
    //     expect(await badgesContract.name()).to.equal('Otter')
    // })

    // it("should revert with message 'mintWithPermission: invalid signature', when given a bad signature", async () => {
    //     await badgesContract.deployed()
    //     const provider = waffle.provider
    //     const sig = {
    //         v: 28,
    //         r: 'junk r value',
    //         s: 'junk s value',
    //         compact: 'jumk conpact value',
    //         yParityAndS: 'junk parity value',
    //         _vs: 'blah',
    //     }
    //     const sigAsBytes = ethers.utils.hexlify(ethers.utils.toUtf8Bytes(JSON.stringify(sig)))
    //     const issuerWallet = new Wallet('0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80', provider)
    //     await expect(
    //         badgesContract.mintWithPermission(issuerWallet.address, 'https://someURI.com', sigAsBytes)
    //     ).to.be.revertedWith('mintWithPermission: invalid signature')
    // })

    it('should mint with a valid signature', async () => {
        // fetch contract address here
        const deployedContract = await badgesContract.deployed()
        console.log('🚀 ~ it ~ deployedContract.address', deployedContract.address)

        const provider = waffle.provider
        // console.log('🚀 ~ it ~ provider', provider)
        // make sure wallets (private keys) have a balance (clamant needs balance)
        const issuerWallet = new Wallet('0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80', provider)
        const redeemerWallet = new Wallet(
            '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d',
            provider
        )

        const domain = {
            name,
            version,
            chainId: 1,
            verifyingContract: deployedContract.address.toLowerCase(),
        }

        const types = {
            MintPermit: [
                {
                    name: 'chainedAddress',
                    type: 'address',
                },
                // {
                //     name: 'to',
                //     type: 'address',
                // },
                // {
                //     name: 'tokenURI',
                //     type: 'string',
                // },
            ],
        }

        // The data to sign
        const value = {
            from: issuerWallet.address,
            // to: redeemerWallet.address,
            // tokenURI: 'https://someURI.com',
        }

        const domain1 = {
            name,
            version,
            chainId: 1,
            verifyingContract: deployedContract.address,
        }

        const types1 = {
            MintPermit: [{ name: 'chainedAddress', type: 'address' }],
        }

        const value1 = {
            chainedAddress: redeemerWallet.address,
        }

        const signature = await issuerWallet._signTypedData(domain1, types1, value1)
        const { v, r, s, compact, yParityAndS, _vs } = splitSignature(signature)
        const sig = { v, r, s, compact, yParityAndS, _vs }

        const hash = _TypedDataEncoder.hash(domain1, types1, value1)

        const res = await badgesContract.isValidIssuerSig(redeemerWallet.address, v, r, s)

        // const res = await badgesContract.mintWithPermission(issuerWallet.address, 'https://someURI.com', sig.compact)
        console.log('🚀 ~ it ~ res', res)
        expect(res).to.equal(true)
    })
})

// mint with authorized signatures succeeds

// payloads of off-chain and on-chain events are the same
