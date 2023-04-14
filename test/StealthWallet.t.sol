pragma solidity 0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Test } from "forge-std/Test.sol";
import { StealthWallet } from "contracts/StealthWallet.sol";
import { PayMaster } from "contracts/PayMaster.sol";
import { UserOperation, UserOperationLib } from "contracts/lib/UserOperation.sol";
import { IEntryPoint } from "contracts/interfaces/IEntryPoint.sol";

import "forge-std/console.sol";

contract StealthWalletTest is Test {
    using SafeERC20 for IERC20;
    using UserOperationLib for UserOperation;

    uint256 goerliChaindId = 5;
    address public constant goerliEntryPoint = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;
    // FIXME to be updated
    address public constant goerliDAI = 0x73967c6a0904aA032C103b4104747E88c566B1A2;

    IEntryPoint entryPoint = IEntryPoint(goerliEntryPoint);
    StealthWallet stealthWallet;
    PayMaster payMaster;

    uint256 ownerPrivateKey = uint256(1);
    address owner = vm.addr(ownerPrivateKey);

    function setUp() public {
        stealthWallet = new StealthWallet(owner, goerliEntryPoint);
        payMaster = new PayMaster(owner, goerliEntryPoint);

        deal(owner, 1000 ether);
        deal(address(payMaster), 1000 ether);
        deal(goerliDAI, owner, 1000 ether);
        deal(goerliDAI, address(stealthWallet), 1000);
        vm.startPrank(owner);
        IERC20(goerliDAI).safeApprove(address(stealthWallet), type(uint256).max);
        payMaster.deposit{ value: 10 ether }();
        vm.stopPrank();

        vm.label(owner, "owner");
        vm.label(address(stealthWallet), "stealthWallet");
        vm.label(address(payMaster), "payMaster");
    }

    function testHandleOps() public {
        uint256 balanceBefore = IERC20(goerliDAI).balanceOf(address(stealthWallet));
        console.log(balanceBefore);

        // compose calldata and user operations
        bytes memory erc20Calldata = abi.encodeWithSelector(IERC20.transfer.selector, owner, 1000);
        bytes memory walletExecData = abi.encodeWithSelector(StealthWallet.executeOps.selector, goerliDAI, erc20Calldata, 0);
        uint256 validUntil = block.timestamp + 1 weeks;
        uint256 validAfter = block.timestamp - 1 weeks;
        bytes memory pmData = abi.encodePacked(address(payMaster), validUntil, validAfter, bytes(""));
        UserOperation memory up = UserOperation({
            sender: address(stealthWallet),
            nonce: 0, // FIXME
            initCode: bytes(""),
            callData: walletExecData,
            callGasLimit: 1000000,
            verificationGasLimit: 1000000,
            preVerificationGas: 100000,
            maxFeePerGas: 10000000,
            maxPriorityFeePerGas: 1000000,
            paymasterAndData: pmData,
            signature: bytes("") // will be ignore when doing hash
        });
        bytes memory userSig = _signUserOperation(ownerPrivateKey, this.getUserOpHash(up, address(stealthWallet), goerliChaindId));
        up.signature = userSig;
        UserOperation[] memory ups = new UserOperation[](1);
        ups[0] = up;

        // send to EP
        vm.prank(owner);
        entryPoint.handleOps(ups, payable(owner));

        // check state changes
        uint256 balanceAfter = IERC20(goerliDAI).balanceOf(address(stealthWallet));
        console.log(balanceAfter);
    }

    function getUserOpHash(UserOperation calldata userOp, address target, uint256 chainId) external view returns (bytes32) {
        return keccak256(abi.encode(userOp.hash(), target, chainId));
    }

    function _signUserOperation(uint256 _privateKey, bytes32 hash) private view returns (bytes memory sig) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, hash);
        return abi.encodePacked(r, s, v);
    }
}
