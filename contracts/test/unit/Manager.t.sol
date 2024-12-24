// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {Base_Test} from "./Base.t.sol";

contract Manager_Test is Base_Test {
    function test_deposit() public {
        deal(address(manager.asset()), address(this), 10e18);
        manager.asset().approve(address(manager), 10e18);
        manager.deposit(10e18, address(this));
    }
}