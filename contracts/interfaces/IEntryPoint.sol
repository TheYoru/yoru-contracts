pragma solidity ^0.8.17;

import { UserOperation } from "@account-abstraction/core/BaseAccount.sol";

import { IAggregator } from "./IAggregator.sol";
import { IStakeManager } from "./IStakeManager.sol";

interface IEntryPoint is IStakeManager {
    //UserOps handled, per aggregator
    struct UserOpsPerAggregator {
        UserOperation[] userOps;
        // aggregator address
        IAggregator aggregator;
        // aggregated signature
        bytes signature;
    }

    /// @return the deposit (for gas payment) of the account
    function balanceOf(address account) external view returns (uint256);

    function handleOps(UserOperation[] calldata ops, address payable beneficiary) external;

    function handleAggregatedOps(UserOpsPerAggregator[] calldata opsPerAggregator, address payable beneficiary) external;

    function getUserOpHash(UserOperation calldata userOp) external view returns (bytes32);

    function simulateValidation(UserOperation calldata userOp) external;

    function getSenderAddress(bytes memory initCode) external;

    function simulateHandleOp(UserOperation calldata op, address target, bytes calldata targetCallData) external;
}
