// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {Base_Test} from "./Base.t.sol";

contract Unlock_Test is Base_Test {
    function test_batching() external {
        address TEST_USER = address(0x99);

        // TODO: This should test the actual signing logic
        //       It is hard coded for now because we need to 
        //       fix the manager address.
        unlock(TEST_USER, address(this));
        assertTrue(manager.isUnlocked(TEST_USER));
    }
}