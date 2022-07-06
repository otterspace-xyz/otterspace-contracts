import { Signer } from 'ethers'
import { splitSignature } from 'ethers/lib/utils'

interface Signature {
    v: number
    r: string
    s: string
    yParityAndS: string
    compact: string
    _vs: string
}

const BADGES_ADDRESS = process.env['NEXT_PUBLIC_BADGES_ADDRESS'] // '0x5fbdb2315678afecb367f032d93f642f64180aa3' // TODO from env

// TODO  can we check this programmatically to prevent on-chain verification failure when the wrong domain name is used?
const BADGES_NAME = process.env['NEXT_PUBLIC_BADGES_NAME']

const TYPES = {
    //Change to MintPermit
    Claim: [
        {
            name: 'from',
            type: 'address',
        },
        {
            name: 'to',
            type: 'address',
        },
        {
            name: 'tokenURI',
            type: 'string',
        },
    ],
}

const signVoucher = async (
    signer: Signer,
    claimantAddress: string,
    tokenURI: string,
    chainId: number
): Promise<Signature> => {
    // persis these params when we test, so the state is consistent
    const domain = {
        name: 'Badges',
        version: '0.3.0',
        // different for each chain (rinkeby, anvil, hardhat, etc.)
        chainId,
        verifyingContract: BADGES_ADDRESS,
    }

    const fromAddress = await signer.getAddress()

    const value = {
        from: fromAddress,
        to: claimantAddress,
        tokenURI,
    }
    const untypedSigner = signer as any // because _signTypedData only exists in Signer subclasses Wallet and JsonRpcSigner
    const signature = await untypedSigner._signTypedData(domain, TYPES, value)
    // payload has to match exactly
    //signture we use is "compact"
    const { v, r, s, compact, yParityAndS, _vs } = splitSignature(signature)
    const sig = { v, r, s, compact, yParityAndS, _vs }
    return sig
}

export default signVoucher
