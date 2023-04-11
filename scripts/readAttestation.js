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
  // Example parameters
  const creatorAddr = '0x76D84163bc0BbF58d6d3F2332f8A9c5B339dF983'
  const subjectAddr = '0x76D84163bc0BbF58d6d3F2332f8A9c5B339dF983'
  const key = ethers.utils.formatBytes32String('otterspace')

  const hexValue = await readAttestation(creatorAddr, subjectAddr, key)
  const attestationValue = hexValue.toString()
  console.log('Attestation value:', attestationValue)
})()
