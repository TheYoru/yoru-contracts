pragma solidity ^0.8.17;

import { UserOperation } from "@account-abstraction/core/BaseAccount.sol";

interface IAggregator {
    function validateSignatures(UserOperation[] calldata userOps, bytes calldata signature) external view;

    function validateUserOpSignature(UserOperation calldata userOp) external view returns (bytes memory sigForUserOp);

    function aggregateSignatures(UserOperation[] calldata userOps) external view returns (bytes memory aggregatedSignature);
}
