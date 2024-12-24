// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {Base_Test} from "./Base.t.sol";

contract Manager_Test is Base_Test {
    // We need to differentiate between unit test
    // and fuzz tests.
    // In unit tests we use Oracle Mock. 
    // In fuzz tests we need to change the oracle
    // price manually.
    function test_deposit() public {
        // wsteth._mint(address(this), 10e18);
    }
}