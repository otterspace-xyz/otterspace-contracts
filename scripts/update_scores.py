import sys
import os
import shutil

"""
This code compares two CSV files and outputs a new CSV file with only the rows that have been changed between them. 
The script takes in two file paths as arguments and uses two functions to read and filter the data.
It saves the updated scores to updated-scores.csv

UX: 
- Export csv from google sheets
- Drop the csv into the ./scripts/data folder
- run the script

HOW TO RUN:
- navigate to the ./scripts directory  `cd ./scripts`
- run `python update_scores.py <old_csv> <new_csv>`

EX:
compare the previous "latest-scores.csv" file with something you've just exported from google sheets and placed into the /data directory
python update_scores.py ./data/latest-scores.csv ./data/12-5-23-export.csv

After running the script, you can run the publish script 
`npx hardhat run publishAttestations.js --network optimisticEthereum`

(you can also test by changing the network to --network optimismGoerli)
"""

def read_csv(file_path):
    with open(file_path, 'r') as file:
        data = file.readlines()
        rows = [row.strip().split(',') for row in data]
    return rows

def filter_changed_rows(old_csv, new_csv):
    old_data = read_csv(old_csv)
    new_data = read_csv(new_csv)

    # Extract and preserve the header (first row) from the new_data
    header = new_data[0]

    old_data_set = {tuple(row) for row in old_data[1:]}
    new_data_set = {tuple(row) for row in new_data[1:]}

    changed_rows = new_data_set - old_data_set

    return header, changed_rows  # Return the header as well

def update_latest_scores(latest_scores_file, header, changed_rows):
    with open(latest_scores_file, 'w') as file:
        # Write the header to the latest-scores.csv file
        file.write(','.join(header) + '\n')

        for row in changed_rows:
            file.write(','.join(row) + '\n')

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <old_csv> <new_csv>")
        sys.exit(1)

    latest_scores_file = './data/latest-scores.csv'

    old_csv = sys.argv[1]
    new_csv = sys.argv[2]

    header, changed_rows = filter_changed_rows(old_csv, new_csv)  # Get the header as well

    if changed_rows:
        update_latest_scores(latest_scores_file, header, changed_rows)
    else:
        print("No changes detected between the two CSV files.")
