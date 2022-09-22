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


def main():
    dev = accounts.add(config["wallets"]["from_key"])
    print(network.show_active())
    # merkleRoot = 0x22bd6cc328747d5b7b89b8fecae38a7979e93ded08803dc8e51412905fcafce6
    # base_uri = "ipfs://bafybeih56lk6istzo42eie4kpsoengalm73axfhmprylzdaazdhxgs7vmi"
    contract = Polyfaucet.deploy(
        # merkleRoot,
        # base_uri,
        # addresses,
        {"from": dev},
        publish_source=get_publish_source(),
    )
    
    # Brownies console.log equivalent   
    # have to add emit events in contract...
    print()
    events = contract.tx.events # dictionary
    if "Log" in events:
        for e in events["Log"]:
            print(e['message'])
    print()

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
