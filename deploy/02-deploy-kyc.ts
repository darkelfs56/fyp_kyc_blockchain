import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import verify from "../utils/verify"
import { networkConfig, developmentChains } from "../helper-hardhat-config"

const deployKYC: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  // @ts-ignore
  const { getNamedAccounts, deployments, network } = hre
  const { deploy, log } = deployments
  const { deployer } = await getNamedAccounts()
  // const chainId: number = network.config.chainId!
  console.log("network is: ", network.name)

  log("----------------------------------------------------")
  log("Deploying KYC and waiting for confirmations...")
  const KYC = await deploy("KYC", {
    from: deployer,
    args: [],
    log: true,
    // we need to wait if on a live network so we can verify properly
    waitConfirmations: networkConfig[network.name].blockConfirmations || 0,
  })
  log(`KYC deployed at ${KYC.address}`)
  if (
    !developmentChains.includes(network.name) &&
    network.etherscan?.apiKey
  ) {
    await verify(KYC.address, [])
  }
}
export default deployKYC
deployKYC.tags = ["all", "KYC"]
