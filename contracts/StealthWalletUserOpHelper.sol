// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./StealthWallet.sol";
import "./StealthWalletFactory.sol";

contract StealthWalletUserOpHelper {
    using UserOperationLib for UserOperation;

    address public immutable entryPoint;
    address public immutable stealthWalletFactory;

    constructor(address _entryPoint, address _stealthWalletFactory) {
        entryPoint = _entryPoint;
        stealthWalletFactory = _stealthWalletFactory;
    }

    function transferERC20_withInitcode_withPaymaster_UserOp(
        address token,
        address tokenRecipient,
        uint256 tokenAmount,
        address walletOwner,
        uint256 salt,
        address payMaster,
        uint256 currentTimestamp,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas
    ) external view returns (UserOperation memory userOp, bytes32 userOpHash) {
        bytes memory userOpCalldata = _packERC20TransferToUserOpCalldata(address(token), tokenRecipient, tokenAmount);

        bytes memory initCodePayload = _packStealthWalletInitCode(walletOwner, salt);
        address newWalletAddress = StealthWalletFactory(stealthWalletFactory).getAddress(walletOwner, salt);

        bytes memory paymasterData = _packPaymasterData(address(payMaster), currentTimestamp + 1 days, currentTimestamp - 1 days);

        userOp = UserOperation({
            sender: newWalletAddress,
            nonce: 0,
            initCode: initCodePayload,
            callData: userOpCalldata,
            callGasLimit: 500000,
            verificationGasLimit: 1500000,
            preVerificationGas: 100000,
            maxFeePerGas: maxFeePerGas,
            maxPriorityFeePerGas: maxPriorityFeePerGas,
            paymasterAndData: paymasterData,
            signature: bytes("") // will be ignore when doing hash
        });
        userOpHash = this.getUserOpHash(userOp, block.chainid);
    }

    function transferETH_withInitcode_withPaymaster_UserOp(
        address ethRecipient,
        uint256 ethAmount,
        address walletOwner,
        uint256 salt,
        address payMaster,
        uint256 currentTimestamp,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas
    ) external view returns (UserOperation memory userOp, bytes32 userOpHash) {
        bytes memory userOpCalldata = _packETHTransferUserOpCalldata(ethRecipient, ethAmount);

        bytes memory initCodePayload = _packStealthWalletInitCode(walletOwner, salt);
        address newWalletAddress = StealthWalletFactory(stealthWalletFactory).getAddress(walletOwner, salt);

        bytes memory paymasterData = _packPaymasterData(address(payMaster), currentTimestamp + 1 days, currentTimestamp - 1 days);

        userOp = UserOperation({
            sender: newWalletAddress,
            nonce: 0,
            initCode: initCodePayload,
            callData: userOpCalldata,
            callGasLimit: 500000,
            verificationGasLimit: 1500000,
            preVerificationGas: 100000,
            maxFeePerGas: maxFeePerGas,
            maxPriorityFeePerGas: maxPriorityFeePerGas,
            paymasterAndData: paymasterData,
            signature: bytes("") // will be ignore when doing hash
        });
        userOpHash = this.getUserOpHash(userOp, block.chainid);
    }

    function transferERC20_withInitcode_UserOp(
        address token,
        address tokenRecipient,
        uint256 tokenAmount,
        address walletOwner,
        uint256 salt,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas
    ) external view returns (UserOperation memory userOp, bytes32 userOpHash) {
        bytes memory userOpCalldata = _packERC20TransferToUserOpCalldata(address(token), tokenRecipient, tokenAmount);

        bytes memory initCodePayload = _packStealthWalletInitCode(walletOwner, salt);
        address newWalletAddress = StealthWalletFactory(stealthWalletFactory).getAddress(walletOwner, salt);

        userOp = UserOperation({
            sender: newWalletAddress,
            nonce: 0,
            initCode: initCodePayload,
            callData: userOpCalldata,
            callGasLimit: 500000,
            verificationGasLimit: 1500000,
            preVerificationGas: 100000,
            maxFeePerGas: maxFeePerGas,
            maxPriorityFeePerGas: maxPriorityFeePerGas,
            paymasterAndData: bytes(""),
            signature: bytes("") // will be ignore when doing hash
        });
        userOpHash = this.getUserOpHash(userOp, block.chainid);
    }

    function transferETH_withInitcode_UserOp(
        address ethRecipient,
        uint256 ethAmount,
        address walletOwner,
        uint256 salt,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas
    ) external view returns (UserOperation memory userOp, bytes32 userOpHash) {
        bytes memory userOpCalldata = _packETHTransferUserOpCalldata(ethRecipient, ethAmount);

        bytes memory initCodePayload = _packStealthWalletInitCode(walletOwner, salt);
        address newWalletAddress = StealthWalletFactory(stealthWalletFactory).getAddress(walletOwner, salt);

        userOp = UserOperation({
            sender: newWalletAddress,
            nonce: 0,
            initCode: initCodePayload,
            callData: userOpCalldata,
            callGasLimit: 500000,
            verificationGasLimit: 1500000,
            preVerificationGas: 100000,
            maxFeePerGas: maxFeePerGas,
            maxPriorityFeePerGas: maxPriorityFeePerGas,
            paymasterAndData: bytes(""),
            signature: bytes("") // will be ignore when doing hash
        });
        userOpHash = this.getUserOpHash(userOp, block.chainid);
    }

    function transferERC20_UserOp(
        address wallet,
        address token,
        address tokenRecipient,
        uint256 tokenAmount,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas
    ) external view returns (UserOperation memory userOp, bytes32 userOpHash) {
        bytes memory userOpCalldata = _packERC20TransferToUserOpCalldata(address(token), tokenRecipient, tokenAmount);

        userOp = UserOperation({
            sender: wallet,
            nonce: 0,
            initCode: bytes(""),
            callData: userOpCalldata,
            callGasLimit: 500000,
            verificationGasLimit: 1500000,
            preVerificationGas: 100000,
            maxFeePerGas: maxFeePerGas,
            maxPriorityFeePerGas: maxPriorityFeePerGas,
            paymasterAndData: bytes(""),
            signature: bytes("") // will be ignore when doing hash
        });
        userOpHash = this.getUserOpHash(userOp, block.chainid);
    }

    function transferETH_UserOp(
        address wallet,
        address ethRecipient,
        uint256 ethAmount,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas
    ) external view returns (UserOperation memory userOp, bytes32 userOpHash) {
        bytes memory userOpCalldata = _packETHTransferUserOpCalldata(ethRecipient, ethAmount);

        userOp = UserOperation({
            sender: wallet,
            nonce: 0,
            initCode: bytes(""),
            callData: userOpCalldata,
            callGasLimit: 500000,
            verificationGasLimit: 1500000,
            preVerificationGas: 100000,
            maxFeePerGas: maxFeePerGas,
            maxPriorityFeePerGas: maxPriorityFeePerGas,
            paymasterAndData: bytes(""),
            signature: bytes("") // will be ignore when doing hash
        });
        userOpHash = this.getUserOpHash(userOp, block.chainid);
    }

    /**
     * Function to pack a transfer ETH action
     * @param transferTo The address to transfer to
     * @param transferAmount The amount of ETH to transfer
     * @return data The data to put in callData in userOp
     */
    function _packETHTransferUserOpCalldata(address transferTo, uint256 transferAmount) internal pure returns (bytes memory data) {
        return abi.encodeWithSignature("execute(address,uint256,bytes)", transferTo, transferAmount, bytes(""));
    }

    /**
     * Function to pack a ERC20 transfer action
     * @param token Token address
     * @param to The address to transfer to
     * @param amount The amount of token to transfer
     */
    function _packERC20TransferToUserOpCalldata(address token, address to, uint256 amount) internal pure returns (bytes memory data) {
        return abi.encodeWithSignature("execute(address,uint256,bytes)", token, 0, abi.encodeWithSignature("transfer(address,uint256)", to, amount));
    }

    /**
     * Pack the initCode for StealthWallet. (Nonce for CREATE2 is always 0)
     * @param walletOwner The owner of this created wallet, private key of owner is needed to sign userOp
     * @param salt The salt to create wallet
     * @return data The data to put in initCode in userOp
     */
    function _packStealthWalletInitCode(address walletOwner, uint256 salt) internal view returns (bytes memory data) {
        bytes memory createPayload = abi.encodeWithSignature("createAccount(address,uint256)", walletOwner, salt);
        return abi.encodePacked(stealthWalletFactory, createPayload);
    }

    function _packPaymasterData(address payMaster, uint256 validUntil, uint256 validAfter) internal pure returns (bytes memory data) {
        return abi.encodePacked(payMaster, validUntil, validAfter, bytes(""));
    }

    function getUserOpHash(UserOperation calldata userOp, uint256 chainId) external view returns (bytes32) {
        return keccak256(abi.encode(userOp.hash(), entryPoint, chainId));
    }
}
