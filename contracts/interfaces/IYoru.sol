pragma solidity ^0.8.17;

interface IYoru {
    // amount or tokenid
    event Announcement(address indexed receiver, uint256 amount, address indexed token, bytes32 pkx, bytes32 ciphertext);

    function sendEth(address payable _recipient, bytes32 _pkx, bytes32 _ciphertext) external payable;

    function sendERC20(address _recipient, address _tokenAddr, uint256 _amount, bytes32 _pkx, bytes32 _ciphertext) external;

    function sendERC721(address _recipient, address _tokenAddr, uint256 _tokenId, bytes32 _pkx, bytes32 _ciphertext) external;
}
