import * as ethers from "ethers"
import { abi as factoryAbi } from "../artifacts/StealthWalletFactory.sol/StealthWalletFactory.json"

async function main() {
    const factoryAddress = "0x49625Ecb229789BCb17FdF1bbbf7aD1875cD0B10"

    const provider = new ethers.JsonRpcProvider(
        "",
    )
    const wallet = new ethers.Wallet(
        "",
        provider,
    )
    const factory = new ethers.Contract(factoryAddress, factoryAbi, wallet)

    const newAddress = await factory.getFunction("getAddress")(
        wallet.address,
        ethers.hexlify(ethers.randomBytes(32)),
    )
    console.log(newAddress)
}

main().then(() => process.exit(0))
