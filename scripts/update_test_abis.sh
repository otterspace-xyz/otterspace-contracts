# copy artifacts
cp artifacts/src/Badges.sol/Badges.json test/abis/latest/Badges.json
cp artifacts/src/Raft.sol/Raft.json test/abis/latest/Raft.json
cp artifacts/src/SpecDataHolder.sol/SpecDataHolder.json test/abis/latest/SpecDataHolder.json

# run testUpgrade
npx hardhat testUpgrade

# check if there were any errors
if [ $? -ne 0 ]
then
    echo "Errors were detected during testUpgrade. Aborting commit."
    exit 1
fi
