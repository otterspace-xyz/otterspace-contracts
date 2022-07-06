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
    const chainId = 31337
    const tokenURI = "blah"

    const issuerWallet = new Wallet('0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80')
    const claimantWallet = new Wallet('0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d')

    beforeEach(async () => {
        const Badges = await ethers.getContractFactory('Badges')
        // needs to match my domain object below
        badgesContract = await Badges.deploy(name, symbol, version)
    })

    it('Should deploy the contract with the right params', async function () {
        await badgesContract.deployed()
        const deployedContractName = await badgesContract.name()
        const deployedSymbolName = await badgesContract.symbol()
        expect(deployedContractName).to.equal(name)
        expect(deployedSymbolName).to.equal(symbol)

        const provider = waffle.provider
        const network = await provider.getNetwork()
        const deployedToChainId = network.chainId
        expect(deployedToChainId).to.equal(chainId)
    })

    it('should match off-chain hash & sig to on-chain', async () => {
        const domain = {
            name: name,
            version: version,
            chainId,
            verifyingContract: badgesContract.address,
        }

        const types = {
            Claim: [{ name: 'fromAddress', type: 'address' }],
        }

        const value = {
            fromAddress: issuerWallet.address,
        }

        const offChainHash = _TypedDataEncoder.hash(domain, types, value)
        const onChainHash = await badgesContract.genDataHash(value.fromAddress)

        expect(offChainHash).to.equal(onChainHash)

        const signature = await issuerWallet._signTypedData(domain, types, value)
        const { v, r, s, compact, yParityAndS, _vs } = splitSignature(signature)
        const isValid = await badgesContract.isValidIssuerSig(issuerWallet.address, v, r, s)

        expect(isValid).to.equal(true)
    })

    // it('should mint with permission', async () => {
    //     const domain = {
    //         name: name,
    //         version: version,
    //         chainId,
    //         verifyingContract: badgesContract.address,
    //     }

    //     const types = {
    //         MintPermit: [
    //             { name: 'from', type: 'address' },
    //             { name: 'to', type: 'address' },
    //             { name: 'tokenURI', type: 'string' }
    //         ],
    //     }

    //     const value = {
    //         from: issuerWallet.address,
    //         to: claimantWallet.address,
    //         tokenURI: tokenURI,
    //     }

    //     const offChainHash = _TypedDataEncoder.hash(domain, types, value)
    //     const onChainHash = await badgesContract.getHash(value.from, value.to, value.tokenURI)

    //     expect(offChainHash).to.equal(onChainHash)

    //     // const signature = await claimantWallet._signTypedData(domain, types, value)
    //     // const { v, r, s, compact, yParityAndS, _vs } = splitSignature(signature)
    //     // const isValid = await badgesContract.isValidIssuerSig(claimantWallet.address, v, r, s)

    //     // expect(isValid).to.equal(true)
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

    // it('should mint with a valid signature', async () => {
    //     // fetch contract address here
    //     const deployedContract = await badgesContract.deployed()
    //     console.log('🚀 ~ it ~ deployedContract.address', deployedContract.address)

    //     const provider = waffle.provider
    //     // console.log('🚀 ~ it ~ provider', provider)
    //     // make sure wallets (private keys) have a balance (clamant needs balance)
    //     const issuerWallet = new Wallet('0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80', provider)
    //     const claimantWallet = new Wallet(
    //         '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d',
    //         provider
    //     )

    //     // const domain = {
    //     //     name,
    //     //     version,
    //     //     chainId: 1,
    //     //     verifyingContract: deployedContract.address.toLowerCase(),
    //     // }

    //     // const types = {
    //     //     MintPermit: [
    //     //         {
    //     //             name: 'chainedAddress',
    //     //             type: 'address',
    //     //         },
    //     //         // {
    //     //         //     name: 'to',
    //     //         //     type: 'address',
    //     //         // },
    //     //         // {
    //     //         //     name: 'tokenURI',
    //     //         //     type: 'string',
    //     //         // },
    //     //     ],
    //     // }

    //     // // The data to sign
    //     // const value = {
    //     //     from: issuerWallet.address,
    //     //     // to: claimantWallet.address,
    //     //     // tokenURI: 'https://someURI.com',
    //     // }

    //     const domain1 = {
    //         name,
    //         version,
    //         chainId: 1,
    //         verifyingContract: deployedContract.address,
    //     }

    //     const types1 = {
    //         Claim: [{ name: 'chainedAddress', type: 'address' }],
    //     }

    //     const value1 = {
    //         chainedAddress: claimantWallet.address,
    //     }

    //     const signature = await issuerWallet._signTypedData(domain1, types1, value1)
    //     const { v, r, s, compact, yParityAndS, _vs } = splitSignature(signature)
    //     const sig = { v, r, s, compact, yParityAndS, _vs }

    //     // const hash = _TypedDataEncoder.hash(domain1, types1, value1)

    //     const res = await badgesContract.isValidIssuerSig(claimantWallet.address, v, r, s)

    //     // const res = await badgesContract.mintWithPermission(issuerWallet.address, 'https://someURI.com', sig.compact)
    //     console.log('🚀 ~ it ~ res', res)
    //     expect(res).to.equal(true)
    // })
})

// mint with authorized signatures succeeds

// payloads of off-chain and on-chain events are the same
