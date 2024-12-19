// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import {Test} from "forge-std/src/Test.sol";

contract CI_Test is Test {
    function test_ci_pass() external pure {
        assertEq(true, true);
    }
}