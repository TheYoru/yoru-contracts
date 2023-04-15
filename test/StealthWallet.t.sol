pragma solidity 0.8.17;

import { Test } from "forge-std/Test.sol";
import { UserOperation, UserOperationLib } from "@account-abstraction/core/BaseAccount.sol";
import { IEntryPoint } from "@account-abstraction/interfaces/IEntryPoint.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { StealthWallet } from "contracts/StealthWallet.sol";
import { StealthWalletFactory } from "contracts/StealthWalletFactory.sol";
import { PayMaster } from "contracts/PayMaster.sol";

import { StealthWalletUtils } from "./utils/StealthWalletUtils.sol";
import { ERC20Mintable } from "./utils/ERC20Mintable.sol";

contract StealthWalletTest is Test {
    using UserOperationLib for UserOperation;

    // address public constant entrypoint = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789; // new
    address public constant entrypoint = 0x0576a174D229E3cFA37253523E645A78A0C91B57; // old

    address walletOwner;
    uint256 walletOwnerKey;
    address receiver = makeAddr("receiver");

    PayMaster payMaster;
    StealthWalletFactory public stealthWalletFactory;
    StealthWallet public stealthWallet;
    StealthWalletUtils public helpers = new StealthWalletUtils();

    ERC20Mintable token;

    function setUp() public {
        (walletOwner, walletOwnerKey) = makeAddrAndKey("owner");

        payMaster = new PayMaster(walletOwner, entrypoint);
        stealthWalletFactory = new StealthWalletFactory(entrypoint);
        token = new ERC20Mintable("Test Token", "TT");

        // Setup paymaster
        deal(address(payMaster), 1 ether);
        payMaster.deposit{ value: 1 ether }();

        vm.label(walletOwner, "walletOwner");
        vm.label(address(payMaster), "payMaster");
        vm.label(address(stealthWallet), "stealthWallet");
        vm.label(address(stealthWalletFactory), "stealthWalletFactory");
    }

    function testStealthWalletGeneration() public {
        uint256 salt = 0;
        address expectedWalletAccountAddress = stealthWalletFactory.getAddress(walletOwner, salt);
        stealthWallet = stealthWalletFactory.createAccount(walletOwner, salt);
        address owner = stealthWallet.owner();
        assertEq(address(stealthWallet), expectedWalletAccountAddress);
        assertEq(owner, walletOwner);
    }

    function testTransferERC20() public {
        uint256 salt = 0;
        stealthWallet = stealthWalletFactory.createAccount(walletOwner, salt);

        vm.deal(address(stealthWallet), 1 ether);
        token.mint(address(stealthWallet), 100 ether);
        assertEq(token.balanceOf(address(stealthWallet)), 100 ether);

        bytes memory userOpCalldata = helpers.packERC20TransferToUserOpCalldata(address(token), receiver, token.balanceOf(address(stealthWallet)));

        // Signature does not matter here since getUserOpHash() will truncate it
        UserOperation memory userOp = UserOperation({
            sender: address(stealthWallet),
            nonce: 0,
            initCode: bytes(""),
            callData: userOpCalldata,
            callGasLimit: 1000000,
            verificationGasLimit: 500000,
            preVerificationGas: 100000,
            maxFeePerGas: 1500000000,
            maxPriorityFeePerGas: 1500000000,
            paymasterAndData: bytes(""),
            signature: bytes("") // will be ignore when doing hash
        });

        bytes32 userOpHash = this.getUserOpHash(userOp, block.chainid);

        userOp.signature = _signUserOperation(walletOwnerKey, userOpHash);

        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = userOp;

        IEntryPoint(entrypoint).handleOps(ops, payable(walletOwner));

        assertEq(token.balanceOf(address(stealthWallet)), 0);
        assertEq(token.balanceOf(receiver), 100 ether);
    }

    function testTransferERC20WithInitCode() public {
        uint256 salt = 1;
        address newWalletAddress = stealthWalletFactory.getAddress(walletOwner, salt);

        vm.deal(newWalletAddress, 1 ether);
        token.mint(newWalletAddress, 100 ether);
        assertEq(token.balanceOf(newWalletAddress), 100 ether);

        bytes memory userOpCalldata = helpers.packERC20TransferToUserOpCalldata(address(token), receiver, token.balanceOf(newWalletAddress));

        bytes memory initCodePayload = helpers.packStealthWalletInitCode(walletOwner, salt, address(stealthWalletFactory));

        UserOperation memory userOp = UserOperation({
            sender: newWalletAddress,
            nonce: 0,
            initCode: initCodePayload,
            callData: userOpCalldata,
            callGasLimit: 1500000,
            verificationGasLimit: 1500000,
            preVerificationGas: 1000000,
            maxFeePerGas: 1500000000,
            maxPriorityFeePerGas: 1500000000,
            paymasterAndData: bytes(""),
            signature: bytes("") // will be ignore when doing hash
        });
        bytes32 userOpHash = this.getUserOpHash(userOp, block.chainid);
        userOp.signature = _signUserOperation(walletOwnerKey, userOpHash);

        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = userOp;

        IEntryPoint(entrypoint).handleOps(ops, payable(walletOwner));

        assertEq(token.balanceOf(newWalletAddress), 0);
        assertEq(token.balanceOf(receiver), 100 ether);
    }

    function testTransferERC20WithInitCodeByPasmaster() public {
        uint256 salt = 2;
        address newWalletAddress = stealthWalletFactory.getAddress(walletOwner, salt);

        vm.deal(newWalletAddress, 1 ether);
        token.mint(newWalletAddress, 100 ether);
        assertEq(token.balanceOf(newWalletAddress), 100 ether);

        bytes memory userOpCalldata = helpers.packERC20TransferToUserOpCalldata(address(token), receiver, token.balanceOf(newWalletAddress));

        bytes memory initCodePayload = helpers.packStealthWalletInitCode(walletOwner, salt, address(stealthWalletFactory));

        bytes memory paymasterData = helpers.packPaymasterData(address(payMaster), block.timestamp + 1 weeks, block.timestamp - 1 weeks);

        UserOperation memory userOp = UserOperation({
            sender: newWalletAddress,
            nonce: 0,
            initCode: initCodePayload,
            callData: userOpCalldata,
            callGasLimit: 1500000,
            verificationGasLimit: 1500000,
            preVerificationGas: 1000000,
            maxFeePerGas: 1500000000,
            maxPriorityFeePerGas: 1500000000,
            paymasterAndData: paymasterData,
            signature: bytes("") // will be ignore when doing hash
        });
        bytes32 userOpHash = this.getUserOpHash(userOp, block.chainid);
        userOp.signature = _signUserOperation(walletOwnerKey, userOpHash);

        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = userOp;

        uint256 paymasterBalanceBefore = IEntryPoint(entrypoint).balanceOf(address(payMaster));
        IEntryPoint(entrypoint).handleOps(ops, payable(walletOwner));
        uint256 paymasterBalanceAfter = IEntryPoint(entrypoint).balanceOf(address(payMaster));

        assertEq(token.balanceOf(newWalletAddress), 0);
        assertEq(token.balanceOf(receiver), 100 ether);
        assertTrue(paymasterBalanceAfter < paymasterBalanceBefore);
    }

    function getUserOpHash(UserOperation calldata userOp, uint256 chainId) external pure returns (bytes32) {
        return keccak256(abi.encode(userOp.hash(), entrypoint, chainId));
    }

    function _signUserOperation(uint256 _privateKey, bytes32 userOpHash) internal pure returns (bytes memory sig) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, ECDSA.toEthSignedMessageHash(userOpHash));
        return abi.encodePacked(r, s, v);
    }
}
