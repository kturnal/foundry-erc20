// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {OurToken} from "../src/OurToken.sol";

interface MintableToken {
    function mint(address, uint256) external;
}

contract OurTokenTest is Test {
    OurToken public ourToken;
    DeployOurToken public deployer;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");

    uint256 public constant STARTING_BALANCE = 100 ether;

    // Redefine the Transfer event so we can use expectEmit in tests.
    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        // Transfer an initial balance to Bob.
        vm.prank(msg.sender);
        ourToken.transfer(bob, STARTING_BALANCE);
    }

    // Existing tests

    function testInitialSupply() public view {
        assertEq(ourToken.totalSupply(), deployer.INITIAL_SUPPLY());
    }

    function testUsersCantMint() public {
        vm.expectRevert();
        MintableToken(address(ourToken)).mint(address(this), 1);
    }

    function testBobBalance() public view {
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE);
    }

    function testAllowancesWork() public {
        uint256 initialAllowance = 1000;
        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);

        uint256 transferAmount = 500;
        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);

        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
        assertEq(ourToken.balanceOf(alice), transferAmount);
    }

    // ---------------------------
    // Additional Tests
    // ---------------------------

    /// @notice Tests a direct transfer between accounts.
    function testDirectTransfer() public {
        uint256 transferAmount = 50;
        vm.prank(bob);
        bool success = ourToken.transfer(alice, transferAmount);
        assertTrue(success);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
        assertEq(ourToken.balanceOf(alice), transferAmount);
    }

    /// @notice Ensures that a transfer fails when the sender does not have enough tokens.
    function testTransferInsufficientBalance() public {
        // Alice has no tokens at this point.
        vm.prank(alice);
        vm.expectRevert();
        ourToken.transfer(bob, 1);
    }

    /// @notice Verifies that transferring tokens to the zero address reverts.
    function testTransferToZeroAddress() public {
        vm.prank(bob);
        vm.expectRevert();
        ourToken.transfer(address(0), 10);
    }

    /// @notice Tests that approving an allowance properly sets it.
    function testApproveAllowance() public {
        uint256 allowanceAmount = 1000;
        vm.prank(bob);
        bool success = ourToken.approve(alice, allowanceAmount);
        assertTrue(success);
        assertEq(ourToken.allowance(bob, alice), allowanceAmount);
    }

    /// @notice Ensures that transferFrom fails if the allowance is insufficient.
    function testTransferFromInsufficientAllowance() public {
        vm.prank(bob);
        ourToken.approve(alice, 50);
        vm.prank(alice);
        vm.expectRevert();
        ourToken.transferFrom(bob, alice, 60);
    }

    /// @notice Verifies that after a transferFrom, the allowance decreases by the correct amount.
    function testAllowanceReductionAfterTransferFrom() public {
        uint256 initialAllowance = 1000;
        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);

        uint256 transferAmount = 300;
        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);

        assertEq(ourToken.allowance(bob, alice), initialAllowance - transferAmount);
    }

    /// @notice Tests updating an allowance by calling approve again.
    function testUpdateAllowance() public {
        // First, Bob approves Alice for 100 tokens.
        vm.prank(bob);
        bool success = ourToken.approve(alice, 100);
        assertTrue(success);
        assertEq(ourToken.allowance(bob, alice), 100);

        // Then, Bob updates the approval to 150 tokens.
        vm.prank(bob);
        success = ourToken.approve(alice, 150);
        assertTrue(success);
        assertEq(ourToken.allowance(bob, alice), 150);
    }

    /// @notice Confirms that token metadata (name, symbol, decimals) is set correctly.
    function testTokenMetadata() public view {
        assertEq(ourToken.name(), "OurToken");
        assertEq(ourToken.symbol(), "OT");
        assertEq(ourToken.decimals(), 18);
    }

    /// @notice Verifies that the total supply remains constant after transfers.
    function testTotalSupplyRemainsConstant() public {
        uint256 initialSupply = ourToken.totalSupply();
        vm.prank(bob);
        ourToken.transfer(alice, 10);
        assertEq(ourToken.totalSupply(), initialSupply);
    }

    /// @notice Ensures that a Transfer event is emitted correctly on token transfers.
    function testTransferEventEmitted() public {
        uint256 transferAmount = 20;
        vm.prank(bob);
        // Set expectations for the Transfer event.
        vm.expectEmit(true, true, false, true);
        emit Transfer(bob, alice, transferAmount);
        ourToken.transfer(alice, transferAmount);
    }
}
