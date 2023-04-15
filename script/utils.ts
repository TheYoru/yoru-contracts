import { Signer, Wallet, providers } from "ethers"
import fs from "fs"
import * as path from "path"
import { config, ethers, network } from "hardhat"
import { default as prompts } from "prompts"
import { execSync } from "child_process"
import simpleGit from "simple-git"
import { randomBytes } from "crypto"
import { logger } from "./logger"

const MAINNET_NETWORK = "mainnet"
const HARDHAT_NETWORK = "hardhat"

const networkName =
    network.name === MAINNET_NETWORK || network.name === HARDHAT_NETWORK
        ? MAINNET_NETWORK
        : network.name

const entryPoint = "0x0576a174D229E3cFA37253523E645A78A0C91B57"

export function isMainnet() {
    return networkName === MAINNET_NETWORK
}

export function isHardhatNetwork() {
    return network.name === HARDHAT_NETWORK
}

export function getEntryPointAddress() {
    return entryPoint
}

// Impersonate multiple accounts
export async function impersonateAccounts(addrs: string[]) {
    for (const addr of addrs) {
        await network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [addr],
        })
    }
}

export function getDeployConfig() {
    const configPath = path.join(config.paths["root"], "scripts", networkName, "config")
    const deployConf = require(configPath)
    return deployConf
}

// Keyin a gas value based on initial and maximum values.
export async function promptNumber(
    valueName: string,
    options: { initial?: number; max?: number; min?: number } = {},
): Promise<number> {
    options.initial = options.initial ?? 0
    options.max = options.max ?? Number.MAX_SAFE_INTEGER
    options.min = options.min ?? 0

    const promptResult = await prompts(
        {
            type: "number",
            name: "value",
            message: `Please choose a(n) ${valueName} for next TX (Need greater than default: ${options.initial}):`,
            ...options,
        },
        {
            onCancel: async function () {
                console.log(`${valueName} is required`)
                process.exit(0)
            },
        },
    )
    return promptResult.value
}

// Determining gas fee options/override data depends on the network supports whether EIP-1559 or legacy type.
export async function getFeeOption(): Promise<providers.FeeData> {
    // Get fee data from network status
    const feeData = await ethers.provider.getFeeData()

    // Auto-detect fee type
    if (feeData.maxFeePerGas != null && feeData.maxPriorityFeePerGas != null) {
        // Support EIP-1559
        logger.info(`Transaction fee use EIP1559 Type (Type 2)`)
        return await promptEip1559FeeData()
    }
    // Not support EIP-1559
    logger.info(`Transaction fee is Legacy Type (Type 0)`)
    return await promptLegacyFeeData()
}

// Keyin gas data on networks "non-supports" EIP-1559.
export async function promptLegacyFeeData(): Promise<providers.FeeData> {
    return {
        maxPriorityFeePerGas: null,
        maxFeePerGas: null,
        gasPrice: await promptGasPrice(),
    }
}

// Keyin gas data on networks supports EIP-1559.
export async function promptEip1559FeeData(): Promise<providers.FeeData> {
    const gWei = ethers.utils.parseUnits("1", "gwei")

    // Get fee data from network status
    const feeData = await ethers.provider.getFeeData()
    const initialMaxFee = feeData.maxFeePerGas! // Will not be null type here
    const initialMaxPriorityFee = feeData.maxPriorityFeePerGas! // Will not be null type here

    // Keyin Max Fee Per Gas (= Base Fee Per Block + Max Priority Fee Per Gas)
    const initialMaxFeeInGWei = initialMaxFee.div(gWei).add(1)
    const maxFeeInGWei = await promptNumber("maxFeePerGas (Gwei)", {
        initial: initialMaxFeeInGWei.toNumber(),
        max: initialMaxFeeInGWei.mul(10).toNumber(), // Set max value to avoid user keyin over.
    })
    const maxFee = gWei.mul(maxFeeInGWei)

    // Keyin Max Priority Fee Per Gas
    const initialMaxPriorityFeeInGWei = initialMaxPriorityFee.div(gWei).add(1)
    const maxPriorityFeeInGWei = await promptNumber("maxPriorityFeePerGas (Gwei)", {
        initial: initialMaxPriorityFeeInGWei.toNumber(),
        max: maxFeeInGWei, // priorityFee needs to be less than or equal to maxFee
    })
    const maxPriorityFee = gWei.mul(maxPriorityFeeInGWei)
    return {
        maxPriorityFeePerGas: maxPriorityFee,
        maxFeePerGas: maxFee,
        gasPrice: null,
    }
}

// Keyin and output gasPrice only
export async function promptGasPrice() {
    const gWei = ethers.utils.parseUnits("1", "gwei")

    // Get fee data from network status
    const initialGasPrice = await ethers.provider.getGasPrice()

    // Keyin Gas Price
    const initialGasPriceInGWei = initialGasPrice.div(gWei).add(1)
    // Return the gasPrice in wei
    return gWei.mul(
        await promptNumber("gasPrice (Gwei)", {
            initial: initialGasPriceInGWei.toNumber(),
            max: initialGasPriceInGWei.mul(10).toNumber(), // Set max value to avoid user keyin over.
        }),
    )
}

export function writeContractJson(contractName: string, content) {
    const jsonPath = path.join(config.paths["root"], "script", networkName, `${contractName}.json`)
    if (fs.existsSync(jsonPath)) {
        fs.writeFileSync(jsonPath, JSON.stringify(content, null, 2))
    } else {
        // Create new file if not exist
        fs.appendFileSync(jsonPath, JSON.stringify(content, null, 2))
    }
}

export async function getDeployer() {
    const deployerPrivateKey = process.env.DEPLOYER_PRIVATE_KEY
    if (deployerPrivateKey === undefined) throw Error("Deployer private key not provided")

    const deployer = new ethers.Wallet(deployerPrivateKey, ethers.provider)
    const promptResult = await prompts(
        {
            type: "confirm",
            name: "correct",
            message: `Deployer address: ${deployer.address}, is this correct?`,
        },
        {
            onCancel: async function () {
                console.log("Exit process")
                process.exit(0)
            },
        },
    )

    if (!promptResult.correct) {
        process.exit(0)
    }

    return deployer
}

export async function getOperator() {
    let operator: Wallet
    if (isHardhatNetwork() && !process.env.OPERATOR_PRIVATE_KEY) {
        logger.warn(`You are now in Hardhat network, not in Mainnet!`)
        operator = ethers.Wallet.fromMnemonic(
            process.env.MNEMONIC || "test test test test test test test test test test test junk",
            "m/44'/60'/0'/0/0", // Default Hardhat mnemonic path
            ethers.wordlists.en, // Default Hardhat mnemonic wordlist
        ).connect(ethers.provider) // Connect to current network provider
    } else {
        const operatorPrivateKey = process.env.OPERATOR_PRIVATE_KEY
        if (operatorPrivateKey === undefined) throw Error("Operator private key not provided")
        operator = new ethers.Wallet(operatorPrivateKey, ethers.provider)
    }
    const promptResult = await prompts(
        {
            type: "confirm",
            name: "correct",
            message: `Operator address: ${operator.address}, is this correct?`,
        },
        {
            onCancel: async function () {
                console.log("Exit process")
                process.exit(0)
            },
        },
    )

    if (!promptResult.correct) {
        process.exit(0)
    }

    return operator
}

export async function getProxyAdmin() {
    const adminPrivateKey = process.env.PROXY_ADMIN_PRIVATE_KEY
    if (adminPrivateKey === undefined) throw Error("Proxy admin private key not provided")

    const admin = new ethers.Wallet(adminPrivateKey, ethers.provider)
    const promptResult = await prompts(
        {
            type: "confirm",
            name: "correct",
            message: `Proxy admin address: ${admin.address}, is this correct?`,
        },
        {
            onCancel: async function () {
                console.log("Exit process")
                process.exit(0)
            },
        },
    )

    if (!promptResult.correct) {
        process.exit(0)
    }

    return admin
}

export async function confirmNextContractAddr(deployer: Signer) {
    const contractAddr = ethers.utils.getContractAddress({
        from: await deployer.getAddress(),
        nonce: await deployer.getTransactionCount(),
    })

    const promptResult = await prompts(
        {
            type: "confirm",
            name: "correct",
            message: `Expected new contract address : ${contractAddr}, is this correct?`,
        },
        {
            onCancel: async function () {
                console.log("Exit process")
                process.exit(0)
            },
        },
    )

    if (!promptResult.correct) {
        process.exit(0)
    }

    return
}

export async function verifyContract(cmd: string) {
    const promptResult = await prompts(
        {
            type: "confirm",
            name: "doVerify",
            message: `Verify contract on etherscan\ncmd : ${cmd} ?`,
        },
        {
            onCancel: async function () {
                console.log("Exit process")
                process.exit(0)
            },
        },
    )

    if (promptResult.doVerify) {
        execSync(cmd, { stdio: "inherit" })
    }
}

export async function signAndBroadcast(txRequest, signer) {
    // fill tx request with any missing field
    const fullTxRequest = await signer.populateTransaction(txRequest)

    if (isMainnet()) {
        // Format TX data
        const messageFields: string[] = []
        messageFields.push(`From: ${fullTxRequest.from}`)
        messageFields.push(`To: ${fullTxRequest.to}`)
        if (fullTxRequest.maxPriorityFeePerGas) {
            messageFields.push(
                `MaxPriorityFeePerGas: ${ethers.utils.formatUnits(
                    fullTxRequest.maxPriorityFeePerGas,
                    "gwei",
                )} GWei`,
            )
        }
        if (fullTxRequest.maxFeePerGas) {
            messageFields.push(
                `MaxFeePerGas: ${ethers.utils.formatUnits(
                    fullTxRequest.maxFeePerGas,
                    "gwei",
                )} GWei`,
            )
        }
        if (fullTxRequest.gasPrice) {
            messageFields.push(
                `GasPrice: ${ethers.utils.formatUnits(fullTxRequest.gasPrice, "gwei")} GWei`,
            )
        }
        messageFields.push(`GasLimit: ${fullTxRequest.gasLimit}`)
        messageFields.push(`Data: ${fullTxRequest.data}`)

        // Prompt TX message
        const passCode = randomBytes(4).toString("hex")
        const promptResult = await prompts(
            {
                type: "text",
                name: "broadcastConfirm",
                message:
                    `Confirm mainnet tx details:` +
                    `\n${messageFields.join("\n")}\n\n` +
                    `If this is correct, type '${passCode}' to broadcast`,
            },
            {
                onCancel: async function () {
                    console.log("Exit process")
                    process.exit(0)
                },
            },
        )

        if (promptResult.broadcastConfirm !== passCode) {
            logger.info("Abort")
            process.exit(0)
        }
    }

    // Sign tx without populating any fields
    const signedTx = await signer.signTransaction(fullTxRequest)

    // Broadcast the signed transaction
    const tx = await signer.provider.sendTransaction(signedTx)

    // Parses the transaction properties from a serialized transaction,
    // and print TX Hash, Flashbots info before confirmed block is mined.
    const parseTx = ethers.utils.parseTransaction(signedTx)
    logger.info(`TX Hash: ${parseTx.hash}`)
    logger.info(`Flashbots tx status: https://protect.flashbots.net/tx/${parseTx.hash}`)

    // Wait for transaction to confirm that block has been mined,
    // and return the transaction receipt
    return await tx.wait()
}

export async function getSubmoduleCommit(): Promise<String> {
    const localGit = simpleGit(process.cwd())
    // The result contains not only commit hash so have to split the string.
    // You can run `git submodule status` to get the whole result string.
    const statusResult = await localGit.subModule(["status"])

    // The second sub string is the commit hash
    return statusResult.split(" ")[1]
}
