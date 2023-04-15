pragma solidity 0.8.17;

import { Test } from "forge-std/Test.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { StealthWallet } from "contracts/StealthWallet.sol";
import { StealthWalletFactory } from "contracts/StealthWalletFactory.sol";

/**
 * This contract is for some handy functions targeting StealthWallet & StealthWalletFactory.
 * StealthWalletFactory uses Create2 calculate wallet address.
 * StealthWallet is the example wallet account from officials.
 */
contract StealthWalletUtils is Test {
    /**
     * Function to pack a transfer ETH action
     * @param transferTo The address to transfer to
     * @param transferAmount The amount of ETH to transfer
     * @return data The data to put in callData in userOp
     */
    function packETHTransferUserOpCalldata(address transferTo, uint256 transferAmount) public pure returns (bytes memory data) {
        return abi.encodeWithSignature("execute(address,uint256,bytes)", transferTo, transferAmount, bytes(""));
    }

    /**
     * Function to pack a ERC20 transfer action
     * @param token Token address
     * @param to The address to transfer to
     * @param amount The amount of token to transfer
     */
    function packERC20TransferToUserOpCalldata(address token, address to, uint256 amount) public pure returns (bytes memory data) {
        return abi.encodeWithSignature("execute(address,uint256,bytes)", token, 0, abi.encodeWithSignature("transfer(address,uint256)", to, amount));
    }

    /**
     * Pack the initCode for StealthWallet. (Nonce for CREATE2 is always 0)
     * @param walletOwner The owner of this created wallet, private key of owner is needed to sign userOp
     * @param salt The salt to create wallet
     * @param stealthWalletFactory The account factory that creates the wallet, must use Create2 to calculate wallet address
     * @return data The data to put in initCode in userOp
     */
    function packStealthWalletInitCode(address walletOwner, uint256 salt, address stealthWalletFactory) public pure returns (bytes memory data) {
        bytes memory createPayload = abi.encodeWithSignature("createAccount(address,uint256)", walletOwner, salt);
        return abi.encodePacked(stealthWalletFactory, createPayload);
    }

    function packPaymasterData(address payMaster, uint256 validUntil, uint256 validAfter) public pure returns (bytes memory data) {
        return abi.encodePacked(payMaster, validUntil, validAfter, bytes(""));
    }

    function deriveWalletAddressFromOwner(address owner, address stealthWalletFactory) public view returns (address walletAddress) {
        return StealthWalletFactory(stealthWalletFactory).getAddress(owner, 0);
    }

    function createWallet(address owner, address stealthWalletFactory) public returns (StealthWallet walletAccount) {
        walletAccount = StealthWalletFactory(stealthWalletFactory).createAccount(owner, 0);
    }
}
