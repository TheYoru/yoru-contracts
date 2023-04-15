import * as ethers from "ethers"
import { abi as tokenAbi } from "../artifacts/ERC20Mintable.sol/ERC20Mintable.json"

async function main() {
    const tokenAddress = "0x74D4872e4FDFdF14B4Eb228D66Ff6F3833E95F07"

    const provider = new ethers.JsonRpcProvider(
        "",
    )
    const wallet = new ethers.Wallet(
        "",
        provider,
    )
    const token = new ethers.Contract(tokenAddress, tokenAbi, wallet)

    const feeData = await provider.getFeeData()
    console.log(feeData)

    const tx = await token.mint(wallet.address, ethers.parseUnits("100"), {
        maxFeePerGas: feeData.maxFeePerGas! * 3n,
        maxPriorityFeePerGas: feeData.maxPriorityFeePerGas! * 3n,
    })
    const reciept = await tx.wait()
    console.log(`Tx hash: ${reciept.transactionHash}`)
}

main().then(() => process.exit(0))
