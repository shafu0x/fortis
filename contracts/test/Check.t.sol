// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import {Test} from "forge-std/src/Test.sol";

contract Check is Test {
    function test_pass() external pure returns (bool) {
        assertEq(true, true);
    }
}