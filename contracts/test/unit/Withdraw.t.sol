// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {Base_Test} from "./Base.t.sol";

contract Withdraw_Test is Base_Test {
    function test_withdraw() public 
        _giveAssets(alice, 100e18) 
        _startPrank(alice)
        _depositTo (100e18, alice, alice)
    {
        manager.withdraw(50e18, alice, alice);

        assertEq(manager.deposited(alice), 50e18);
    }

    function test_withdraw_afterMint() public 
        _giveAssets(alice, 100e18) 
        _startPrank(alice)
        _depositTo (100e18, alice, alice)
        _mintFUSD  (1e18, alice, alice)
    {
        uint crBefore = manager.collatRatio(alice);
        manager.withdraw(50e18, alice, alice);
        uint crAfter  = manager.collatRatio(alice);

        assertTrue(crBefore > crAfter);
        assertEq(manager.deposited(alice), 50e18);
    }
}