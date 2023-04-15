import * as ethers from "ethers"
import { abi as userOpHelperAbi } from "../artifacts/StealthWalletUserOpHelper.sol/StealthWalletUserOpHelper.json"

async function main() {
    const tokenAddress = "0x74D4872e4FDFdF14B4Eb228D66Ff6F3833E95F07"
    const paymasterAddress = "0xe45f063B5370e62D544dC6EcF2dd14EbecA0cd55"
    const userOpHelperAddress = "0xe45f063B5370e62D544dC6EcF2dd14EbecA0cd55"

    const provider = new ethers.JsonRpcProvider("")
    const wallet = new ethers.Wallet("", provider)
    const userOpHelper = new ethers.Contract(userOpHelperAddress, userOpHelperAbi, wallet)

    const feeData = await provider.getFeeData()
    console.log(feeData)

    const salt = ethers.hexlify(ethers.randomBytes(32))
    const res = await userOpHelper.transferERC20_withInitcode_withPaymaster_UserOp(
        tokenAddress,
        wallet.address, // token recipient
        ethers.parseUnits("100"), // token amount
        wallet.address, // wallet owner
        salt,
        paymasterAddress,
        Math.floor(Date.now() / 1000), // current timestamp
        feeData.maxFeePerGas?.toString(),
        feeData.maxPriorityFeePerGas?.toString(),
    )
    const userOp = res[0]
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
    console.log(`User Op Hash: ${res[1]}`)
}

main().then(() => process.exit(0))
