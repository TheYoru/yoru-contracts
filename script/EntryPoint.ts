import * as ethers from "ethers"
import { abi as entryPointAbi } from "../artifacts/IEntryPoint.sol/IEntryPoint.json"
import { abi as factoryAbi } from "../artifacts/StealthWalletFactory.sol/StealthWalletFactory.json"
import { abi as userOpHelperAbi } from "../artifacts/StealthWalletUserOpHelper.sol/StealthWalletUserOpHelper.json"
import { abi as yoruAbi } from "../artifacts/Yoru.sol/Yoru.json"

async function main() {
    const entryPointAddress = "0x0576a174D229E3cFA37253523E645A78A0C91B57"
    const tokenAddress = "0x74D4872e4FDFdF14B4Eb228D66Ff6F3833E95F07"
    const paymasterAddress = "0xb666fE2b562be86590c4DF43F12Ab1DBA9EC209C"
    const factoryAddress = "0xb1ae118a4f5089812296BC2714a0cB261f99cEBb"
    const yoruAddress = "0x8D977171D2515f375d0E8E8623e7e27378eE70Fa"
    const userOpHelperAddress = "0x63087b831D80Db6f65930339cFA38D4f7E486db3"

    const provider = new ethers.providers.JsonRpcProvider(
        "",
    )
    const wallet = new ethers.Wallet(
        "",
        provider,
    )
    const entryPoint = new ethers.Contract(entryPointAddress, entryPointAbi, wallet)
    const factory = new ethers.Contract(factoryAddress, factoryAbi, wallet)
    const yoru = new ethers.Contract(yoruAddress, yoruAbi, wallet)
    const userOpHelper = new ethers.Contract(userOpHelperAddress, userOpHelperAbi, wallet)

    const feeData = await provider.getFeeData()
    // console.log(feeData)

    // Sender send
    const walletOwner = wallet.address
    const r = ethers.utils.hexlify(ethers.utils.randomBytes(32))
    const salt = ethers.utils.keccak256(r)
    const stealthWalletAddress = await factory.getAddress(walletOwner, salt)
    console.log(
        `Owner: ${walletOwner}, r: ${r} and salt: ${salt} -> stealth wallet address: ${stealthWalletAddress}`,
    )

    const tokenRecipientAddress = stealthWalletAddress
    const transferAmount = ethers.utils.parseUnits("10")
    const fakePkx = ethers.utils.hexlify(ethers.utils.randomBytes(32))
    const fakeCiphertext = ethers.utils.hexlify(ethers.utils.randomBytes(32))
    console.log(
        `Transferring ${ethers.utils.parseEther(
            transferAmount.toString(),
        )} tokens to ${tokenRecipientAddress}`,
    )
    const transferTx = await yoru.sendERC20(
        tokenRecipientAddress,
        tokenAddress,
        transferAmount,
        fakePkx,
        fakeCiphertext,
        {
            // maxFeePerGas: feeData.maxFeePerGas!.mul(3),
            // maxPriorityFeePerGas: feeData.maxPriorityFeePerGas!.mul(3),
            maxFeePerGas: feeData.maxFeePerGas,
            maxPriorityFeePerGas: feeData.maxPriorityFeePerGas,
        },
    )
    const transferTxReciept = await transferTx.wait()
    console.log(`Transfer Tx hash: ${transferTxReciept.transactionHash}`)

    // Receiver spend
    const spendingRecipient = wallet.address
    console.log(
        `Stealth wallet spending ${ethers.utils.parseEther(
            transferAmount.toString(),
        )} tokens to ${spendingRecipient}`,
    )
    const userOpData = await userOpHelper.transferERC20_withInitcode_withPaymaster_UserOp(
        tokenAddress,
        spendingRecipient, // token recipient
        transferAmount, // token amount
        walletOwner, // wallet owner
        salt,
        paymasterAddress,
        Math.floor(Date.now() / 1000), // current timestamp
        // (feeData.maxFeePerGas!.mul(3)).toString(),
        // (feeData.maxPriorityFeePerGas!.mul(3)).toString(),
        feeData.maxFeePerGas,
        feeData.maxPriorityFeePerGas,
    )
    const userOp = [...userOpData[0]]
    const userOpHash = userOpData[1]
    const userOpSignature = await wallet.signMessage(ethers.utils.arrayify(userOpHash))
    userOp[10] = userOpSignature

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

    // const simulateHandleOpResult = await entryPoint.callStatic.simulateHandleOp(userOp, ethers.constants.AddressZero, "0x")
    // console.log(simulateHandleOpResult)
    // const simulateValidationResult = await entryPoint.callStatic.simulateValidation(userOp)
    // console.log(simulateValidationResult)

    const handleOpsTx = await entryPoint.handleOps([userOp], wallet.address, {
        // maxFeePerGas: feeData.maxFeePerGas!.mul(3),
        // maxPriorityFeePerGas: feeData.maxPriorityFeePerGas!.mul(3),
        maxFeePerGas: feeData.maxFeePerGas,
        maxPriorityFeePerGas: feeData.maxPriorityFeePerGas,
    })
    const handleOpsTxReciept = await handleOpsTx.wait()
    console.log(`HandleOps Tx hash: ${handleOpsTxReciept.transactionHash}`)
}

main().then(() => process.exit(0))
