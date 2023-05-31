const fs = require('fs')
const csvParser = require('csv-parser')
const ethers = require('ethers')
const hardhat = require('hardhat')
const attestationStationAbi = require('./abi/AttestationStationABI.json')
const attestationStationAddress = '0xEE36eaaD94d1Cc1d0eccaDb55C38bFfB6Be06C77'

const csvFilePath = './scripts/data/latest-scores.csv'

const parseCsv = async filePath => {
  const results = []
  return new Promise((resolve, reject) => {
    fs.createReadStream(filePath)
      .pipe(csvParser())
      .on('data', data => results.push(data))
      .on('end', () => {
        resolve(results)
      })
      .on('error', error => {
        reject(error)
      })
  })
}

const createAttestations = async csvData => {
  const [signer] = await hardhat.ethers.getSigners()

  const attestationStationContract = new ethers.Contract(
    attestationStationAddress,
    attestationStationAbi,
    signer
  )
  const attestations = csvData.map(row => {
    const score = parseFloat(row['Score Log'])
    const scoreAsBigNumber = ethers.BigNumber.from(score.toFixed(0))
    console.log('🚀 ~ attestations ~ scoreAsBigNumber:', scoreAsBigNumber)
    return {
      about: row.address,
      key: ethers.utils.formatBytes32String('otterspace.score'),
      val: ethers.utils.defaultAbiCoder.encode(['uint256'], [scoreAsBigNumber]),
    }
  })

  const functionSignature = 'attest((address,bytes32,bytes)[])'
  await attestationStationContract[functionSignature](attestations)
}

;(async () => {
  const csvData = await parseCsv(csvFilePath)
  const res = await createAttestations(csvData)
  console.log('Attestations successfully published!')
})()
