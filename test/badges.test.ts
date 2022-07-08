import { expect } from 'chai'
import { ethers } from 'hardhat'
import { Badges } from '../typechain-types'
import { Wallet } from 'ethers'
import { waffle } from 'hardhat'
import { splitSignature, _TypedDataEncoder } from 'ethers/lib/utils'

describe('Badges', async function () {
    let badgesContract: Badges

    const name = 'Otter'
    const symbol = 'OTTR'
    const version = '1'
    const chainId = 31337
    const tokenURI = 'blah'

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

    it('should match off-chain hash to on-chain hash', async () => {
        const [owner, issuer, claimant, badActor] = await ethers.getSigners()

        const typedData = {
            domain: {
                name: name,
                version: version,
                chainId,
                verifyingContract: badgesContract.address,
            },
            types: {
                MintPermit: [
                    { name: 'from', type: 'address' },
                    { name: 'to', type: 'address' },
                    { name: 'tokenURI', type: 'string' },
                ],
            },
            value: {
                from: issuer.address,
                to: claimant.address,
                tokenURI,
            },
        }

        const offChainHash = _TypedDataEncoder.hash(typedData.domain, typedData.types, typedData.value)
        const onChainHash = await badgesContract.getHash(
            typedData.value.from,
            typedData.value.to,
            typedData.value.tokenURI
        )

        expect(offChainHash).to.equal(onChainHash)
    })

    it('should mint with permission', async () => {
        const [, issuer, claimant] = await ethers.getSigners()

        const typedData = {
            domain: {
                name: name,
                version: version,
                chainId,
                verifyingContract: badgesContract.address,
            },
            types: {
                MintPermit: [
                    { name: 'from', type: 'address' },
                    { name: 'to', type: 'address' },
                    { name: 'tokenURI', type: 'string' },
                ],
            },
            value: {
                from: issuer.address,
                to: claimant.address,
                tokenURI,
            },
        }

        const signature = await issuer._signTypedData(typedData.domain, typedData.types, typedData.value)
        const { v, r, s, compact, yParityAndS, _vs } = splitSignature(signature)

        const txn = await badgesContract
            .connect(claimant)
            .mintWithPermission(typedData.value.from, typedData.value.tokenURI, compact)
        const receipt = await txn.wait()
        expect(receipt.status).to.equal(1)

        const ownerOfMintedToken = await badgesContract.ownerOf(0)
        expect(ownerOfMintedToken).to.equal(claimant.address)

        const balanceOfClaimant = await badgesContract.balanceOf(claimant.address)
        expect(balanceOfClaimant).to.equal(1)

        const newlyMintedTokenId = 0
        const uriOfToken = await badgesContract.tokenURI(newlyMintedTokenId)
        expect(uriOfToken).to.equal(typedData.value.tokenURI)
    })
})

describe('Check different payloads', async function () {
    let badgesContract: Badges
    let typedData: any
    const name = 'Otter'
    const symbol = 'OTTR'
    const version = '1'
    const chainId = 31337
    const tokenURI = 'blah'
    let issuer: any
    let claimant: any

    beforeEach(async () => {
        const Badges = await ethers.getContractFactory('Badges')
        const signers = await ethers.getSigners()
        issuer = signers[0]
        claimant = signers[1]

        // needs to match my domain object below
        badgesContract = await Badges.deploy(name, symbol, version)
        typedData = {
            domain: {
                name: name,
                version: version,
                chainId,
                verifyingContract: badgesContract.address,
            },
            types: {
                MintPermit: [
                    { name: 'from', type: 'address' },
                    { name: 'to', type: 'address' },
                    { name: 'tokenURI', type: 'string' },
                ],
            },
            value: {
                from: issuer.address,
                to: claimant.address,
                tokenURI,
            },
        }
    })

    it('should reject the signature when there is an incorrect from address', async () => {
        const signature = await issuer._signTypedData(typedData.domain, typedData.types, typedData.value)
        const { compact } = splitSignature(signature)
        const randomWallet = Wallet.createRandom()

        await expect(
            badgesContract.connect(claimant).mintWithPermission(randomWallet.address, typedData.value.tokenURI, compact)
        ).to.be.revertedWith('mintWithPermission: invalid signature')
    })

    it('should reject the signature when the URI doesnt match', async () => {
        const signature = await issuer._signTypedData(typedData.domain, typedData.types, typedData.value)
        const { compact } = splitSignature(signature)
        await expect(
            badgesContract
                .connect(claimant)
                .mintWithPermission(typedData.value.from, 'https://some-incorrect-uri.com', compact)
        ).to.be.revertedWith('mintWithPermission: invalid signature')
    })

    it('should reject the signature when the signature is invalid', async () => {
        const sig = { compact: 'junk conpact value' }
        const sigAsBytes = ethers.utils.hexlify(ethers.utils.toUtf8Bytes(JSON.stringify(sig)))

        await expect(
            badgesContract
                .connect(claimant)
                .mintWithPermission(typedData.value.from, typedData.value.tokenURI, sigAsBytes)
        ).to.be.revertedWith('mintWithPermission: invalid signature')
    })
})
