// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { UserOperation, UserOperationLib } from "@account-abstraction/core/BaseAccount.sol";
import { IEntryPoint } from "@account-abstraction/interfaces/IEntryPoint.sol";

import { Ownable } from "./abstracts/Ownable.sol";
import { IPaymaster } from "./interfaces/IPaymaster.sol";

contract PayMaster is IPaymaster, Ownable {
    IEntryPoint public immutable entryPoint;

    uint256 private constant VALID_TIMESTAMP_OFFSET = 20;
    uint256 private constant SIGNATURE_OFFSET = 84;

    modifier onlyEntryPoint() {
        require(msg.sender == address(entryPoint), "not from entry point");
        _;
    }

    constructor(address _owner, address _entryPoint) Ownable(_owner) {
        entryPoint = IEntryPoint(_entryPoint);
    }

    function validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    ) external override onlyEntryPoint returns (bytes memory context, uint256 validationData) {
        (userOpHash, maxCost); // unused

        // TODO check whether initCode has valid factory address
        (uint48 validUntil, uint48 validAfter, ) = _parsePaymasterAndData(userOp.paymasterAndData);

        return ("", _packValidationData(address(0), uint256(validUntil), uint256(validAfter)));
    }

    function postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost) external override onlyEntryPoint {
        (mode, context, actualGasCost); // unused params
        return;
    }

    function _packValidationData(address aggregator, uint256 validUntil, uint256 validAfter) private pure returns (uint256) {
        // first address could be any but zero
        return uint160(aggregator) | (validUntil << 160) | (validAfter << (160 + 48));
    }

    function _parsePaymasterAndData(bytes calldata paymasterAndData) private pure returns (uint48 validUntil, uint48 validAfter, bytes calldata signature) {
        (validUntil, validAfter) = abi.decode(paymasterAndData[VALID_TIMESTAMP_OFFSET:SIGNATURE_OFFSET], (uint48, uint48));
        signature = paymasterAndData[SIGNATURE_OFFSET:];
    }

    //
    //
    //
    // Deposit logic
    //
    //
    //
    function deposit() public payable {
        entryPoint.depositTo{ value: msg.value }(address(this));
    }

    function withdrawTo(address payable withdrawAddress, uint256 amount) public onlyOwner {
        entryPoint.withdrawTo(withdrawAddress, amount);
    }

    function addStake(uint32 unstakeDelaySec) external payable onlyOwner {
        entryPoint.addStake{ value: msg.value }(unstakeDelaySec);
    }

    function getDeposit() public view returns (uint256) {
        return entryPoint.balanceOf(address(this));
    }

    function unlockStake() external onlyOwner {
        entryPoint.unlockStake();
    }

    function withdrawStake(address payable withdrawAddress) external onlyOwner {
        entryPoint.withdrawStake(withdrawAddress);
    }
}
