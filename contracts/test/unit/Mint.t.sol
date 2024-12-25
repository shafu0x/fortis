// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {Base_Test} from "./Base.t.sol";

contract Mint_Test is Base_Test {
    function test_mintFUSD() public 
        giveAssets(alice, 100e18) 
    {
        setAssetPrice(4_000e8);

        vm.startPrank(alice);

        manager.asset().approve(address(manager), 100e18);
        manager.deposit(100e18, alice);
        manager.mintFUSD(250_000e18, alice, alice);

        assertEq(manager.deposited(alice),  100e18);
        assertEq(manager.minted(alice),     250_000e18);
        assertEq(manager.collatRatio(alice), 1.6e18);

        vm.stopPrank();
    }

    function test_mintFUSD_unlocked() public 
        giveAssets(delegate, 100e18)
    {
        vm.startPrank(delegate);
        manager.unlock(sigOwner, delegate, deadline, v, r, s);
        setAssetPrice(4_000e8);

        manager.asset().approve(address(manager), 100e18);
        manager.deposit(100e18, sigOwner);
        manager.mintFUSD(250_000e18, sigOwner, address(this));

        assertEq(manager.deposited(sigOwner),   100e18);
        assertEq(manager.minted(sigOwner),      250_000e18);
        assertEq(manager.collatRatio(sigOwner), 1.6e18);

        vm.stopPrank();
    }
}