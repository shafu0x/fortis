// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {Base_Test} from "./Base.t.sol";

contract Deposit_Test is Base_Test {
    function test_deposit() 
        public 
            giveAssets(alice, 10e18) 
            prank(alice) 
    {
        assertEq(manager.deposits(alice), 0);

        manager.asset().approve(address(manager), 10e18);
        manager.deposit(10e18, alice);

        assertEq(manager.deposits(alice), 10e18);
    }

    function test_deposit_forBob() 
        public 
            giveAssets(alice, 10e18) 
            prank(alice) 
    {
        assertEq(manager.deposits(bob), 0);

        manager.asset().approve(address(manager), 10e18);
        manager.deposit(10e18, bob);

        assertEq(manager.deposits(bob), 10e18);
    }
}