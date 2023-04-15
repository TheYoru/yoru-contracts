import { ethers } from "hardhat"
import * as utils from "./utils"
import { logger } from "./logger"
import * as StealthWalletFactory from "../artifacts/contracts/StealthWalletFactory.sol/StealthWalletFactory.json"

async function main() {
    const deployer = await utils.getDeployer()

    // Deploy StealthWalletFactory
    logger.info("Deploying StealthWalletFactory contract...")
    await utils.confirmNextContractAddr(deployer)

    const contract = await (
        await ethers.getContractFactory(StealthWalletFactory.contractName, deployer)
    ).deploy(utils.getEntryPointAddress(), await utils.getFeeOption())
    await contract.deployed()
    logger.info(`StealthWalletFactory contract address: ${contract.address}`)

    // Write contract JSON
    utils.writeContractJson(StealthWalletFactory.contractName, {
        address: contract.address,
        commit: await utils.getSubmoduleCommit(),
        abi: StealthWalletFactory.abi,
    })
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
