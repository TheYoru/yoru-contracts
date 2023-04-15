pragma solidity 0.8.17;

import { Test } from "forge-std/Test.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { Yoru } from "contracts/Yoru.sol";
import { ERC20Mintable } from "./utils/ERC20Mintable.sol";
import { ERC721Mintable } from "./utils/ERC721Mintable.sol";

contract YoruTest is Test {
    using SafeERC20 for IERC20;

    address internal constant ETH_TOKEN_PLACHOLDER = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address user = makeAddr("user");
    address recipient = makeAddr("recipient");
    ERC20Mintable erc20Token;
    ERC721Mintable erc721Token;

    Yoru yoru;

    event Announcement(address indexed receiver, uint256 amount, address indexed token, bytes32 pkx, bytes32 ciphertext);

    function setUp() public {
        yoru = new Yoru();

        erc20Token = new ERC20Mintable("Test Token", "TT");
        erc721Token = new ERC721Mintable("Test NFT", "TNFT");
        deal(user, 1000 ether);
        erc20Token.mint(user, 100 ether);
        vm.startPrank(user);
        IERC20(erc20Token).safeApprove(address(yoru), type(uint256).max);
        vm.stopPrank();

        vm.label(user, "user");
        vm.label(address(yoru), "yoru");
    }

    function testSendEth() public {
        uint256 amount = 1 ether;
        vm.expectEmit(true, true, true, true);
        emit Announcement(recipient, amount, ETH_TOKEN_PLACHOLDER, bytes32(0), bytes32(0));
        vm.prank(user);
        yoru.sendEth{ value: amount }(payable(recipient), bytes32(0), bytes32(0));
    }

    function testSendERC20() public {
        uint256 amount = 100;
        vm.expectEmit(true, true, true, true);
        emit Announcement(recipient, amount, address(erc20Token), bytes32(0), bytes32(0));
        vm.prank(user);
        yoru.sendERC20(payable(recipient), address(erc20Token), amount, bytes32(0), bytes32(0));
    }

    function testSendERC721() public {
        uint256 tokenId = 1234;
        erc721Token.mint(user, tokenId);
        vm.prank(user);
        erc721Token.approve(address(yoru), tokenId);

        vm.expectEmit(true, true, true, true);
        emit Announcement(recipient, tokenId, address(erc721Token), bytes32(0), bytes32(0));
        vm.prank(user);
        yoru.sendERC20(payable(recipient), address(erc721Token), tokenId, bytes32(0), bytes32(0));
    }
}
