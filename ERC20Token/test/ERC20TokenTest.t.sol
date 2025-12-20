// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ERC20Token} from "../src/ERC20Token.sol";

contract ERC20TokenTest is Test {
    ERC20Token token;

    address owner = address(this);
    address alice = address(0x1);
    address bob = address(0x2);
    address spender = address(0x3);

    uint256 constant INITIAL_MINT = 1_000 ether;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    function setUp() public {
        token = new ERC20Token("TestToken", "TT", 18);
        token.mintToken(owner, INITIAL_MINT);
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    function testConstructorSetsMetadataCorrectly() public {
        assertEq(token.name(), "TestToken");
        assertEq(token.symbol(), "TT");
        assertEq(token.decimals(), 18);
        assertEq(token.owner(), owner);
    }

    /*//////////////////////////////////////////////////////////////
                                MINT
    //////////////////////////////////////////////////////////////*/

    function testOwnerCanMint() public {
        token.mintToken(alice, 100 ether);

        assertEq(token.balanceOf(alice), 100 ether);
        assertEq(token.totalSupply(), INITIAL_MINT + 100 ether);
    }

    function testMintEmitsTransferEvent() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), alice, 50 ether);

        token.mintToken(alice, 50 ether);
    }

    function testNonOwnerCannotMint() public {
        vm.prank(alice);
        vm.expectRevert("Not the Owner");
        token.mintToken(alice, 1 ether);
    }

    /*//////////////////////////////////////////////////////////////
                              TRANSFER
    //////////////////////////////////////////////////////////////*/

    function testTransferSuccess() public {
        token.transfer(alice, 100 ether);

        assertEq(token.balanceOf(alice), 100 ether);
        assertEq(token.balanceOf(owner), INITIAL_MINT - 100 ether);
    }

    function testTransferEmitsEvent() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, alice, 10 ether);

        token.transfer(alice, 10 ether);
    }

    function testTransferFailsIfInsufficientBalance() public {
        vm.prank(alice);
        vm.expectRevert("Insufficient balance");
        token.transfer(bob, 1 ether);
    }

    /*//////////////////////////////////////////////////////////////
                              APPROVE
    //////////////////////////////////////////////////////////////*/

    function testApproveSetsAllowance() public {
        token.approve(spender, 100 ether);

        assertEq(token.allowance(owner, spender), 100 ether);
    }

    function testApproveEmitsEvent() public {
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, 100 ether);

        token.approve(spender, 100 ether);
    }

    function testApproveFailsForZeroAddress() public {
        vm.expectRevert("Invalid address");
        token.approve(address(0), 10 ether);
    }

    /*//////////////////////////////////////////////////////////////
                           TRANSFER FROM
    //////////////////////////////////////////////////////////////*/

    function testTransferFromSuccess() public {
        token.approve(spender, 200 ether);

        vm.prank(spender);
        token.transferFrom(owner, alice, 150 ether);

        assertEq(token.balanceOf(alice), 150 ether);
        assertEq(token.balanceOf(owner), INITIAL_MINT - 150 ether);
        assertEq(token.allowance(owner, spender), 50 ether);
    }

    function testTransferFromEmitsEvent() public {
        token.approve(spender, 50 ether);

        vm.prank(spender);
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, alice, 50 ether);

        token.transferFrom(owner, alice, 50 ether);
    }

    function testTransferFromFailsIfAllowanceTooLow() public {
        token.approve(spender, 10 ether);

        vm.prank(spender);
        vm.expectRevert("Insufficient allowance");
        token.transferFrom(owner, alice, 20 ether);
    }

    function testTransferFromFailsIfBalanceTooLow() public {
        token.approve(spender, INITIAL_MINT + 1);

        vm.prank(spender);
        vm.expectRevert("Insufficient balance");
        token.transferFrom(owner, alice, INITIAL_MINT + 1);
    }

    /*//////////////////////////////////////////////////////////////
                           ALLOWANCE LOGIC
    //////////////////////////////////////////////////////////////*/

    function testAllowanceDecreasesAfterTransferFrom() public {
        token.approve(spender, 100 ether);

        vm.prank(spender);
        token.transferFrom(owner, alice, 40 ether);

        assertEq(token.allowance(owner, spender), 60 ether);
    }

    /*//////////////////////////////////////////////////////////////
                            INVARIANTS
    //////////////////////////////////////////////////////////////*/

    function testTotalSupplyMatchesBalancesAfterMint() public {
        token.mintToken(alice, 100 ether);
        token.mintToken(bob, 50 ether);

        uint256 sumBalances = token.balanceOf(owner) + token.balanceOf(alice) + token.balanceOf(bob);

        assertEq(sumBalances, token.totalSupply());
    }
}
