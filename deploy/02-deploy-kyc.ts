import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import verify from "../utils/verify"
import { networkConfig, developmentChains } from "../helper-hardhat-config"

const deployKYCUpload: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  // @ts-ignore
  const { getNamedAccounts, deployments, network } = hre
  const { deploy, log } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId: number = network.config.chainId!

  // let ethUsdPriceFeedAddress: string
  // if (chainId == 31337) {
  //   const ethUsdAggregator = await deployments.get("MockV3Aggregator")
  //   ethUsdPriceFeedAddress = ethUsdAggregator.address
  // } else {
  //   ethUsdPriceFeedAddress = networkConfig[network.name].ethUsdPriceFeed!
  // }
  log("----------------------------------------------------")
  log("Deploying KYCUpload and waiting for confirmations...")
  const KYCUpload = await deploy("KYCUpload", {
    from: deployer,
    args: [],
    log: true,
    // we need to wait if on a live network so we can verify properly
    waitConfirmations: networkConfig[network.name].blockConfirmations || 0,
  })
  log(`KYCUpload deployed at ${KYCUpload.address}`)
  if (
    !developmentChains.includes(network.name) &&
    process.env.ETHERSCAN_API_KEY
  ) {
    await verify(KYCUpload.address, [])
  }
}
export default deployKYCUpload
deployKYCUpload.tags = ["all", "KYCUpload"]
