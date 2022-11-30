import { ethers, getNamedAccounts, deployments } from "hardhat"

async function main() {
  const { deployer } = await getNamedAccounts()
  console.log(deployer)
  const KYCUpload = await ethers.getContract("KYCUpload", deployer)
  console.log(`Got contract KYCUpload at ${KYCUpload.address}`)

  //get accounts
  const accounts = await ethers.getSigners()

//   console.log("Funding contract...")
//   const transactionResponse = await KYCUpload.fund({
//     value: ethers.utils.parseEther("0.05"),
//   })
//   await transactionResponse.wait()
//   console.log("Funded!")
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
