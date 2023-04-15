import * as ethers from "ethers"
import { abi as factoryAbi } from "../artifacts/StealthWalletFactory.sol/StealthWalletFactory.json"
import { abi as yoruAbi } from "../artifacts/Yoru.sol/Yoru.json"

async function main() {
    const tokenAddress = "0x74D4872e4FDFdF14B4Eb228D66Ff6F3833E95F07"
    const factoryAddress = "0xb1ae118a4f5089812296BC2714a0cB261f99cEBb"
    const yoruAddress = "0x8D977171D2515f375d0E8E8623e7e27378eE70Fa"

    const provider = new ethers.providers.JsonRpcProvider("")
    const wallet = new ethers.Wallet("", provider)
    const yoru = new ethers.Contract(yoruAddress, yoruAbi, wallet)
    const factory = new ethers.Contract(factoryAddress, factoryAbi, wallet)

    const feeData = await provider.getFeeData()
    // console.log(feeData)

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
    const tx = await yoru.sendERC20(
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
    const reciept = await tx.wait()
    console.log(`Tx hash: ${reciept.transactionHash}`)
}

main().then(() => process.exit(0))
