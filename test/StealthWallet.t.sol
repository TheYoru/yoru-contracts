pragma solidity 0.8.17;

import { Test } from "forge-std/Test.sol";
import { UserOperation, UserOperationLib } from "@account-abstraction/core/BaseAccount.sol";
import { IEntryPoint } from "@account-abstraction/interfaces/IEntryPoint.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { StealthWallet } from "contracts/StealthWallet.sol";
import { StealthWalletFactory } from "contracts/StealthWalletFactory.sol";
import { PayMaster } from "contracts/PayMaster.sol";
import { StealthWalletUserOpHelper } from "contracts/StealthWalletUserOpHelper.sol";

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
    StealthWalletUserOpHelper public helper;

    ERC20Mintable token;

    function setUp() public {
        (walletOwner, walletOwnerKey) = makeAddrAndKey("owner");

        payMaster = new PayMaster(walletOwner, entrypoint);
        stealthWalletFactory = new StealthWalletFactory(entrypoint);
        helper = new StealthWalletUserOpHelper(entrypoint, address(stealthWalletFactory));
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

        (UserOperation memory userOp, bytes32 userOpHash) = helper.transferERC20_UserOp(
            address(stealthWallet),
            address(token),
            receiver,
            token.balanceOf(address(stealthWallet)),
            1500000000,
            1500000000
        );
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

        (UserOperation memory userOp, bytes32 userOpHash) = helper.transferERC20_withInitcode_UserOp(
            address(token),
            receiver,
            token.balanceOf(address(newWalletAddress)),
            walletOwner,
            salt,
            1500000000,
            1500000000
        );

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

        (UserOperation memory userOp, bytes32 userOpHash) = helper.transferERC20_withInitcode_withPaymaster_UserOp(
            address(token),
            receiver,
            token.balanceOf(address(newWalletAddress)),
            walletOwner,
            salt,
            address(payMaster),
            block.timestamp,
            1500000000,
            1500000000
        );

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
