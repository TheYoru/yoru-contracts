import * as ethers from "ethers"
import { abi as userOpHelperAbi } from "../artifacts/StealthWalletUserOpHelper.sol/StealthWalletUserOpHelper.json"

async function main() {
    const tokenAddress = "0x74D4872e4FDFdF14B4Eb228D66Ff6F3833E95F07"
    const paymasterAddress = "0xb666fE2b562be86590c4DF43F12Ab1DBA9EC209C"
    const userOpHelperAddress = "0x63087b831D80Db6f65930339cFA38D4f7E486db3"

    const provider = new ethers.providers.JsonRpcProvider(
        "",
    )
    const wallet = new ethers.Wallet(
        "",
        provider,
    )
    const userOpHelper = new ethers.Contract(userOpHelperAddress, userOpHelperAbi, wallet)

    const feeData = await provider.getFeeData()
    // console.log(feeData)

    const salt = ethers.utils.hexlify(ethers.utils.randomBytes(32))
    const res = await userOpHelper.transferERC20_withInitcode_withPaymaster_UserOp(
        tokenAddress,
        wallet.address, // token recipient
        ethers.utils.parseUnits("100"), // token amount
        wallet.address, // wallet owner
        salt,
        paymasterAddress,
        Math.floor(Date.now() / 1000), // current timestamp
        feeData.maxFeePerGas?.toString(),
        feeData.maxPriorityFeePerGas?.toString(),
    )
    const userOp = [...res[0]]
    const userOpHash = res[1]
    console.log(`User Op (signature is empty):`)
    console.log(`- sender: ${userOp[0]}`)
    console.log(`- noce: ${userOp[1]}`)
    console.log(`- initCode: ${userOp[2]}`)
    console.log(`- callData: ${userOp[3]}`)
    console.log(`- callGasLimit: ${userOp[4]}`)
    console.log(`- verificationGasLimit: ${userOp[5]}`)
    console.log(`- preVerificationGas: ${userOp[6]}`)
    console.log(`- maxFeePerGas: ${userOp[7]}`)
    console.log(`- maxPriorityFeePerGas: ${userOp[8]}`)
    console.log(`- paymasterAndData: ${userOp[9]}`)
    console.log(`- signature: ${userOp[10]}`)
    console.log(`User Op Hash: ${userOpHash}`)
}

main().then(() => process.exit(0))
