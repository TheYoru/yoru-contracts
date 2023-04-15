// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

import "./StealthWallet.sol";

contract StealthWalletFactory {
    address public immutable EntryPoint;

    constructor(address _entryPoint) {
        EntryPoint = _entryPoint;
    }

    /**
     * create an account, and return its address.
     * returns the address even if the account is already deployed.
     * Note that during UserOperation execution, this method is called only if the account is not deployed.
     * This method returns an existing account address so that entryPoint.getSenderAddress() would work even after account creation
     */
    function createAccount(address owner, uint256 salt) public returns (StealthWallet ret) {
        address addr = getAddress(owner, salt);
        uint codeSize = addr.code.length;
        if (codeSize > 0) {
            return StealthWallet(addr);
        }
        ret = new StealthWallet{ salt: bytes32(salt) }(EntryPoint, owner);
    }

    /**
     * calculate the counterfactual address of this account as it would be returned by createAccount()
     */
    function getAddress(address owner, uint256 salt) public view returns (address) {
        return Create2.computeAddress(bytes32(salt), keccak256(abi.encodePacked(type(StealthWallet).creationCode, abi.encode(EntryPoint, owner))));
    }
}
