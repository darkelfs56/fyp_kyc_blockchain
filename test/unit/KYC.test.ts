import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { assert, expect } from "chai"
import { network, deployments, ethers, config } from "hardhat"
import { developmentChains } from "../../helper-hardhat-config"
import { KYC } from "../../typechain-types"

describe("KYC", function () {
  let kyc: KYC
  let deployer: SignerWithAddress
  beforeEach(async () => {
    if (!developmentChains.includes(network.name)) {
      throw "You need to be on a development chain to run tests"
    }
    const accounts = await ethers.getSigners()
    deployer = accounts[0]
    await deployments.fixture(["KYC"])
    kyc = await ethers.getContract("KYC")
  })

  describe("constructor", function () {
    it("Should set the owner correctly", async () => {
      const response = await kyc.getOwner()
      assert.equal(response, deployer.address)
    })
  })

  describe("addUsers", function () {
    it("should add user", async () => {
      console.log("Hardhat config is: ", config.solidity.compilers[0].settings)
      const accounts = await ethers.getSigners()
      await kyc.connect(accounts[1]).addUsers("Muhammad Akmal bin Anuar", "lol", "22/3/2000")
      const userCount = (await kyc.connect(accounts[1]).getOwnUserCount(accounts[1].address)).toNumber()
      assert.notEqual(userCount, 0)
    })
  })
})