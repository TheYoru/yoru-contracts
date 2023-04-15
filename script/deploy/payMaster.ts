import { ethers } from "hardhat"
import * as utils from "./utils"
import { logger } from "./logger"
import * as PayMaster from "../artifacts/contracts/PayMaster.sol/PayMaster.json"

async function main() {
    const deployer = await utils.getDeployer()

    // Deploy PayMaster
    logger.info("Deploying PayMaster contract...")
    await utils.confirmNextContractAddr(deployer)

    const contract = await (
        await ethers.getContractFactory(PayMaster.contractName, deployer)
    ).deploy(deployer.address, utils.getEntryPointAddress(), await utils.getFeeOption())
    await contract.deployed()
    logger.info(`PayMaster contract address: ${contract.address}`)

    // Write contract JSON
    utils.writeContractJson(PayMaster.contractName, {
        address: contract.address,
        commit: await utils.getSubmoduleCommit(),
        abi: PayMaster.abi,
    })
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
