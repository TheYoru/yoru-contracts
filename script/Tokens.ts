import * as ethers from "ethers"
import { abi as tokenAbi } from "../artifacts/ERC20Mintable.sol/ERC20Mintable.json"

async function main() {
    const tokenAddress = "0x74D4872e4FDFdF14B4Eb228D66Ff6F3833E95F07"
    const yoruAddress = "0x8D977171D2515f375d0E8E8623e7e27378eE70Fa"

    const provider = new ethers.providers.JsonRpcProvider("")
    const wallet = new ethers.Wallet("", provider)
    const token = new ethers.Contract(tokenAddress, tokenAbi, wallet)

    const feeData = await provider.getFeeData()
    // console.log(feeData)

    // Mint tx
    const mintTx = await token.mint(wallet.address, ethers.utils.parseUnits("100"), {
        maxFeePerGas: feeData.maxFeePerGas!.mul(3),
        maxPriorityFeePerGas: feeData.maxPriorityFeePerGas!.mul(3),
    })
    const mintTxReciept = await mintTx.wait()
    console.log(`Mint Tx hash: ${mintTxReciept.transactionHash}`)

    // Approve Tx
    const approveTx = await token.approve(yoruAddress, ethers.utils.parseUnits("10000"), {
        maxFeePerGas: feeData.maxFeePerGas!.mul(3),
        maxPriorityFeePerGas: feeData.maxPriorityFeePerGas!.mul(3),
    })
    const approveTxReciept = await approveTx.wait()
    console.log(`Approve Tx hash: ${approveTxReciept.transactionHash}`)
}

main().then(() => process.exit(0))
