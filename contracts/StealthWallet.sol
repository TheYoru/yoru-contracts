// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { BaseAccount, IEntryPoint, UserOperation, UserOperationLib } from "@account-abstraction/core/BaseAccount.sol";

import { Ownable } from "./abstracts/Ownable.sol";
import { IERC1271Wallet } from "./interfaces/IERC1271Wallet.sol";

contract StealthWallet is Ownable, BaseAccount, IERC1271Wallet {
    using ECDSA for bytes32;

    address private immutable _entryPoint;

    // bytes4(keccak256("isValidSignature(bytes32,bytes)"))
    bytes4 internal constant ERC1271_MAGICVALUE = 0x1626ba7e;

    // Require the function call went through EntryPoint or owner
    function _requireFromEntryPointOrOwner() internal view {
        require(msg.sender == address(entryPoint()) || msg.sender == owner, "account: not Owner or EntryPoint");
    }

    constructor(address _entryPoint_, address _owner) Ownable(_owner) {
        _entryPoint = _entryPoint_;
    }

    function entryPoint() public view virtual override returns (IEntryPoint) {
        return IEntryPoint(_entryPoint);
    }

    function nonce() public view virtual override returns (uint256) {
        return 0;
    }

    function _validateAndUpdateNonce(UserOperation calldata userOp) internal override {}

    /// implement template method of BaseAccount
    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash) internal virtual override returns (uint256 validationData) {
        if (owner != userOpHash.toEthSignedMessageHash().recover(userOp.signature)) {
            return SIG_VALIDATION_FAILED;
        }
        return 0;
    }

    function isValidSignature(bytes32 _hash, bytes calldata _signature) external view override returns (bytes4) {
        require(owner == ECDSA.recover(_hash, _signature), "invalid signature");
        return ERC1271_MAGICVALUE;
    }

    /**
     * execute a transaction (called directly from owner, or by entryPoint)
     */
    function execute(address dest, uint256 value, bytes calldata func) external {
        _requireFromEntryPointOrOwner();
        _call(dest, value, func);
    }

    /**
     * execute a sequence of transactions
     */
    function executeBatch(address[] calldata dest, bytes[] calldata func) external {
        _requireFromEntryPointOrOwner();
        require(dest.length == func.length, "wrong array lengths");
        for (uint256 i = 0; i < dest.length; i++) {
            _call(dest[i], 0, func[i]);
        }
    }

    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{ value: value }(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }
}
