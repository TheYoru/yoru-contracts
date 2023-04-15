import * as ethers from "ethers"
import { abi as paymasterAbi } from "../artifacts/PayMaster.sol/PayMaster.json"

async function main() {
    const paymasterAddress = "0xb666fE2b562be86590c4DF43F12Ab1DBA9EC209C"

    const provider = new ethers.providers.JsonRpcProvider(
        "",
    )
    const wallet = new ethers.Wallet(
        "",
        provider,
    )
    const paymaster = new ethers.Contract(paymasterAddress, paymasterAbi, wallet)
    const depositBefore = await paymaster.getDeposit()
    console.log(`Deposit before: ${depositBefore.toString()}`)

    const feeData = await provider.getFeeData()
    // console.log(feeData)

    const tx = await paymaster.deposit({
        value: ethers.utils.parseUnits("0.5"),
        maxFeePerGas: feeData.maxFeePerGas!.mul(3),
        maxPriorityFeePerGas: feeData.maxPriorityFeePerGas!.mul(3),
    })
    const reciept = await tx.wait()
    console.log(`Tx hash: ${reciept.transactionHash}`)

    const depositAfter = await paymaster.getDeposit()
    console.log(`Deposit after: ${depositAfter.toString()}`)
}

main().then(() => process.exit(0))
