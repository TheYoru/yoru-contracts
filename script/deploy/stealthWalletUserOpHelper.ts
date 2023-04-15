import { ethers } from "hardhat"
import * as utils from "./utils"
import { logger } from "./logger"
import * as StealthWalletUserOpHelper from "../artifacts/contracts/StealthWalletUserOpHelper.sol/StealthWalletUserOpHelper.json"

const stealthWalletFactory = "0xb1ae118a4f5089812296BC2714a0cB261f99cEBb"

async function main() {
    const deployer = await utils.getDeployer()

    // Deploy StealthWalletUserOpHelper
    logger.info("Deploying StealthWalletUserOpHelper contract...")
    await utils.confirmNextContractAddr(deployer)

    const contract = await (
        await ethers.getContractFactory(StealthWalletUserOpHelper.contractName, deployer)
    ).deploy(utils.getEntryPointAddress, stealthWalletFactory, await utils.getFeeOption())
    await contract.deployed()
    logger.info(`StealthWalletUserOpHelper contract address: ${contract.address}`)

    // Write contract JSON
    utils.writeContractJson(StealthWalletUserOpHelper.contractName, {
        address: contract.address,
        commit: await utils.getSubmoduleCommit(),
        abi: StealthWalletUserOpHelper.abi,
    })
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
