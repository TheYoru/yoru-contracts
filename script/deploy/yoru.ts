import { ethers } from "hardhat"
import * as utils from "./utils"
import { logger } from "./logger"
import * as Yoru from "../artifacts/contracts/Yoru.sol/Yoru.json"

async function main() {
    const deployer = await utils.getDeployer()

    // Deploy Yoru
    logger.info("Deploying Yoru contract...")
    await utils.confirmNextContractAddr(deployer)

    const contract = await (
        await ethers.getContractFactory(Yoru.contractName, deployer)
    ).deploy(await utils.getFeeOption())
    await contract.deployed()
    logger.info(`Yoru contract address: ${contract.address}`)

    // Write contract JSON
    utils.writeContractJson(Yoru.contractName, {
        address: contract.address,
        commit: await utils.getSubmoduleCommit(),
        abi: Yoru.abi,
    })
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
