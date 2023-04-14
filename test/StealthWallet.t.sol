pragma solidity 0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Test } from "forge-std/Test.sol";
import { StealthWallet } from "contracts/StealthWallet.sol";
import { UserOperation } from "contracts/lib/UserOperation.sol";
import { IEntryPoint } from "contracts/interfaces/IEntryPoint.sol";

contract StealthWalletTest is Test {
    using SafeERC20 for IERC20;

    address public constant goerliEntryPoint = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;
    // FIXME to be updated
    address public constant goerliDAI = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    IEntryPoint entryPoint = IEntryPoint(goerliEntryPoint);
    StealthWallet stealthWallet;

    uint256 ownerPrivateKey = uint256(1);
    address owner = vm.addr(ownerPrivateKey);

    function setUp() public {
        stealthWallet = new StealthWallet(goerliEntryPoint, owner);

        deal(owner, 1000 ether);
        deal(goerliDAI, owner, 1000 ether);
        vm.startPrank(owner);
        IERC20(goerliDAI).safeApprove(address(stealthWallet), type(uint256).max);
        vm.stopPrank();

        // setEOABalanceAndApprove(maker, address(rfq), tokens, 100000);

        vm.label(owner, "owner");
        vm.label(address(stealthWallet), "stealthWallet");
    }

    function testValidateUserOp() public {
        // compose calldata and user operations
        bytes memory erc20Calldata = abi.encodeWithSelector(IERC20.transfer.selector, owner, 100);
        bytes memory walletExecData = abi.encodeWithSelector(StealthWallet.executeOps.selector, goerliDAI, erc20Calldata, 0);
        UserOperation memory up = UserOperation({
            sender: address(stealthWallet),
            nonce: 0, // FIXME
            initCode: bytes(""),
            callData: walletExecData,
            callGasLimit: 1000000,
            verificationGasLimit: 1000000,
            preVerificationGas: 100000,
            maxFeePerGas: 10000,
            maxPriorityFeePerGas: 10000,
            paymasterAndData: bytes(""),
            signature: bytes("")
        });
        UserOperation[] memory ups = new UserOperation[](1);
        ups[0] = up;

        // send to EP
        vm.prank(owner);
        entryPoint.handleOps(ups, payable(owner));

        // check state changes
    }
}
