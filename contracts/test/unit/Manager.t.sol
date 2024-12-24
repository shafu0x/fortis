// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {Base_Test} from "./Base.t.sol";

contract Manager_Test is Base_Test {
    function test_deposit() 
        public 
            giveAssets(alice, 10e18) 
            prank(alice) 
{
        manager.asset().approve(address(manager), 10e18);
        manager.deposit(10e18, address(this));
    }
}