pragma solidity ^0.8.17;

interface IYoru {
    event Announcement(
        address indexed receiver, // stealth address
        uint256 amount, // funds
        address indexed token, // token address or ETH placeholder
        bytes32 pkx, // ephemeral public key x coordinate
        bytes32 ciphertext // encrypted entropy and payload extension
    );
}
