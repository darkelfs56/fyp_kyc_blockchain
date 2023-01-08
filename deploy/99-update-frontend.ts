import { network, ethers } from "hardhat"
import * as fs from "fs"

// const { ethers } = require("hardhat")
// const fs = require("fs")

const FRONT_END_ADDRESSES_FILE = "../fyp_kyc/constants/contractAddresses.json"
const FRONT_END_ABI_FILE = "../fyp_kyc/constants/abi.json"

const updateFrontend = async function () {
  if (process.env.UPDATE_FRONT_END) {
    console.log("Updating frontend...")
    await updateContractAddresses()
    await updateAbi()
  }
}

async function updateAbi() {
  const kyc = await ethers.getContract("KYC")
  fs.writeFileSync(FRONT_END_ABI_FILE, kyc.interface.format(ethers.utils.FormatTypes.json) as string)
  console.log("abi has been updated")
}

async function updateContractAddresses() {
  const kyc = await ethers.getContract("KYC")
  const chainId = network.config.chainId?.toString() as string
  const currentAddresses = JSON.parse(fs.readFileSync(FRONT_END_ADDRESSES_FILE, "utf8"))
  if (chainId in currentAddresses) {
    if (!currentAddresses[chainId].includes(kyc.address)) {
      currentAddresses[chainId].push(kyc.address)
      console.log("Pushed a new address.")
    }
  } else {
    currentAddresses[chainId] = [kyc.address]
    console.log("currentAddress actually exists")
  }
  fs.writeFileSync(FRONT_END_ADDRESSES_FILE, JSON.stringify(currentAddresses))
}

export default updateFrontend
updateFrontend.tags = ["all", "frontend", "KYC"]
