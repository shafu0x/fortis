// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {Base_Test} from "./Base.t.sol";

contract Deployment_Test is Base_Test {
    function test_deployment() external view {
        assertTrue(manager.assetPrice()   != 0);
        assertTrue(manager.wstEth2stEth() != 0);
        assertEq(manager.owner()      , OWNER);
        assertEq(manager.feeReceiver(), OWNER);
        assertEq(fUSD.owner(), address(manager));
    }
}