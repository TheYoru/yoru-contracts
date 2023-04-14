pragma solidity 0.8.17;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { Ownable } from "./abstracts/Ownable.sol";
import { UserOperation } from "./lib/UserOperation.sol";
import { IStealthWallet } from "./interfaces/IStealthWallet.sol";
import { IERC1271Wallet } from "./interfaces/IERC1271Wallet.sol";

contract StealthWallet is Ownable, IStealthWallet, IERC1271Wallet {
    address public immutable entryPoint;

    // bytes4(keccak256("isValidSignature(bytes32,bytes)"))
    bytes4 internal constant ERC1271_MAGICVALUE = 0x1626ba7e;

    // validateUserOp() error codes
    uint256 internal constant SIG_VALIDATION_FAILED = 1;

    modifier onlyEntryPoint() {
        require(msg.sender == entryPoint, "not from entry point");
        _;
    }

    constructor(address _owner, address _entryPoint) Ownable(_owner) {
        entryPoint = _entryPoint;
    }

    function isValidSignature(bytes32 _hash, bytes calldata _signature) external view override returns (bytes4) {
        require(owner == ECDSA.recover(_hash, _signature), "invalid signature");
        return ERC1271_MAGICVALUE;
    }

    // FIXME add nonce to avoid replay attack
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256) external override onlyEntryPoint returns (uint256 validationData) {
        if (owner != ECDSA.recover(userOpHash, userOp.signature)) {
            return SIG_VALIDATION_FAILED;
        }
        return 0;
    }

    function executeOps(address target, bytes calldata data, uint256 value) external onlyEntryPoint {
        (bool success, bytes memory result) = target.call{ value: value }(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }
}
