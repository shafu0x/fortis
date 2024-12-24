// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {Base_Test} from "./Base.t.sol";

contract Mint_Test is Base_Test {
    function test_mintFUSD() public 
        giveAssets(alice, 100e18) 
    {
        vm.startPrank(alice);
        manager.asset().approve(address(manager), 100e18);
        manager.deposit(100e18, alice);
        manager.mintFUSD(1e18, alice, alice);
        vm.stopPrank();
    }
}