const ethers = require('ethers')
const hardhat = require('hardhat')
const attestationStationAbi = require('./abi/AttestationStationABI.json')
const attestationStationAddress = '0xEE36eaaD94d1Cc1d0eccaDb55C38bFfB6Be06C77'

const readAttestation = async (creatorAddr, subjectAddr, key) => {
  const [signer] = await hardhat.ethers.getSigners()

  const attestationStationContract = new ethers.Contract(
    attestationStationAddress,
    attestationStationAbi,
    signer
  )

  const hexValue = await attestationStationContract.attestations(
    creatorAddr,
    subjectAddr,
    key
  )

  const value = ethers.utils.defaultAbiCoder.decode(['uint256'], hexValue)
  return value[0]
}

;(async () => {
  // dont change creator
  const creatorAddr = '0x76D84163bc0BbF58d6d3F2332f8A9c5B339dF983'
  // chaange this one for the person you wanna check
  const subjectAddr = '0x74EF51C27c9984f34b3F7F80E8259cC1bB04e37C'
  const key = ethers.utils.formatBytes32String('otterspace.score')

  const hexValue = await readAttestation(creatorAddr, subjectAddr, key)
  const attestationValue = hexValue.toString()
  console.log('Attestation value:', attestationValue)
})()
