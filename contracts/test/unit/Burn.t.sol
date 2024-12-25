// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {Base_Test} from "./Base.t.sol";

contract Burn_Test is Base_Test {
    function test_burnFUSD() public 
        _giveAssets   (alice, 100e18) 
        _setAssetPrice(4_000e8)
        _startPrank   (alice)
        _deposit      (100e18, alice)
        _mintFUSD     (100e18, alice)
    {
        manager.burnFUSD(80e18, alice);

        assertEq(manager.minted(alice), 20e18);
    }

    function test_burnFUSD_All() public 
        _giveAssets   (alice, 100e18) 
        _setAssetPrice(4_000e8)
        _startPrank   (alice)
        _deposit      (100e18, alice)
        _mintFUSD     (100e18, alice)
    {
        manager.burnFUSD(100e18, alice);

        assertEq(manager.minted(alice), 0);
    }

    function test_burnFUSD_unlocked() public 
        _giveAssets   (delegate, 100e18) 
        _setAssetPrice(4_000e8)
        _startPrank   (delegate)
        _unlock       ()
        _depositTo    (100e18, delegate, sigOwner)
        _mintFUSD     (100e18, sigOwner)
    {
        manager.burnFUSD(100e18, sigOwner);

        assertEq(manager.minted(sigOwner),             0);
        assertEq(manager.wstETH().balanceOf(sigOwner), 0);
    }
}