pragma solidity 0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Test } from "forge-std/Test.sol";
import { StealthWallet } from "contracts/StealthWallet.sol";
import { UserOperation } from "contracts/lib/UserOperation.sol";
import { IEntryPoint } from "contracts/interfaces/IEntryPoint.sol";

contract StealthWalletTest is Test {
    address public constant goerliEntryPoint = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;
    // FIXME to be updated
    address public constant goerliUSDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    IEntryPoint entryPoint = IEntryPoint(goerliEntryPoint);
    StealthWallet stealthWallet;

    uint256 ownerPrivateKey = uint256(1);
    address owner = vm.addr(ownerPrivateKey);

    function setUp() public {
        stealthWallet = new StealthWallet(goerliEntryPoint, owner);

        // deal(maker, 100 ether);
        // setEOABalanceAndApprove(maker, address(rfq), tokens, 100000);

        vm.label(owner, "owner");
        vm.label(address(stealthWallet), "stealthWallet");
    }

    function testValidateUserOp() public {
        bytes memory erc20Calldata = abi.encodeWithSelector(IERC20.transfer.selector, owner, 100);
        bytes memory walletExecData = abi.encodeWithSelector(StealthWallet.executeOps.selector, goerliUSDT, erc20Calldata, 0);
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

        //        UserOperation[] memory up
        // send to EP
        // check the state change
    }
}
