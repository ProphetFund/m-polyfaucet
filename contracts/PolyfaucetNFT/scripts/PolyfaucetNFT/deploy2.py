#!/usr/bin/python3

#############################################################################################
# Usage: brownie run scripts/waterdropNFT/deploy.py
#
#
#############################################################################################

from brownie import Polyfaucet, accounts, network, config
from scripts.helpful_scripts import get_publish_source

# load addresses.csv (skip first line)
import csv
addresses = []
with open('addresses.csv', 'r') as csvfile:
    reader = csv.reader(csvfile)
    # skip first line
    next(reader)
    for row in reader:
        addresses.append(row[0])

addresses = addresses[:]
assert len(addresses) == 1000

# skip first 400
addresses = addresses[400:]
assert len(addresses) == 600


def main():
    dev = accounts.add(config["wallets"]["from_key"])
    print(network.show_active())
    
    
    # load Polyfaucet contract at 0x616d197A29E50EBD08a4287b26e47041286F171D
    contract = Polyfaucet.at("0x616d197A29E50EBD08a4287b26e47041286F171D")
    print(contract.address)

    print("Now AirDropping...")
    # now bulk upload the addresses in 50 address chunks
    running_gas = 0
    for i in range(0, len(addresses), 50):
        tx = contract.bulkAirdrop(addresses[i:i+50], {"from": dev})
        # tx.wait(1) # dont rlly need this
        running_gas += tx.gas_used
        print(f"uploaded addresses {i} to {i+50}")
        print(f"current balance: {dev.balance()}")
        print(f"gas used: {running_gas:,}")
        print()
    # show how expensive in USD its going to be
    MATIC_price = 0.9
    gas_price = 300
    print(gas_price, MATIC_price)
    total_cost = ((running_gas * gas_price) / 10e9) * MATIC_price
    print(f"total cost: ${total_cost}")
    return contract
