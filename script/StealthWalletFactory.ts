import * as ethers from "ethers"
import { abi as factoryAbi } from "../artifacts/StealthWalletFactory.sol/StealthWalletFactory.json"

async function main() {
    const factoryAddress = "0xb1ae118a4f5089812296BC2714a0cB261f99cEBb"

    const provider = new ethers.providers.JsonRpcProvider(
        "",
    )
    const wallet = new ethers.Wallet(
        "",
        provider,
    )
    const factory = new ethers.Contract(factoryAddress, factoryAbi, wallet)

    const newAddress = await factory.getAddress(
        wallet.address,
        ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    )
    console.log(newAddress)
}

main().then(() => process.exit(0))
