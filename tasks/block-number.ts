import { task } from "hardhat/config"

//Code here is required to get fake accounts while using Hardhat
task("accounts", "Prints the list of accounts").setAction(
    async (taskArgs, hre) => {
        const accounts = await hre.ethers.getSigners()

        for (const account of accounts) {
            console.log(account.address)
        }
    }
)

task("block-number", "Prints the current block number").setAction(
    async (taskArgs, hre) => {
        const blockNumber = await hre.ethers.provider.getBlockNumber()
        console.log(`Current block number is: ${blockNumber}`)
    }
)

// module.exports = {}; //js version
export {}
