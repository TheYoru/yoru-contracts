pragma solidity 0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IYoru } from "./interfaces/IYoru.sol";

contract Yoru is IYoru {
    address internal constant ETH_TOKEN_PLACHOLDER = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function sendEth(
        address payable _recipient,
        bytes32 _pkx, // ephemeral public key x coordinate
        bytes32 _ciphertext
    ) external payable {
        require(msg.value > 0, "zero ETH value");
        emit Announcement(_recipient, msg.value, ETH_TOKEN_PLACHOLDER, _pkx, _ciphertext);

        _recipient.transfer(msg.value);
    }

    function sendToken(
        address _recipient,
        address _tokenAddr,
        uint256 _amount,
        bytes32 _pkx, // ephemeral public key x coordinate
        bytes32 _ciphertext
    ) external {
        require(_amount > 0, "zero amount");
        emit Announcement(_recipient, _amount, _tokenAddr, _pkx, _ciphertext);

        SafeERC20.safeTransferFrom(IERC20(_tokenAddr), msg.sender, _recipient, _amount);
    }
}
