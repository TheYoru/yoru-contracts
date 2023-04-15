pragma solidity ^0.8.17;

import { UserOperation } from "@account-abstraction/core/BaseAccount.sol";

interface IStealthWallet {
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds) external returns (uint256 validationData);
}
