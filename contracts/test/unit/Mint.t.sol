// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {Base_Test} from "./Base.t.sol";

contract Mint_Test is Base_Test {
    function test_mintFUSD() public 
        _giveAssets   (alice, 100e18) 
        _setAssetPrice(4_000e8)
        _startPrank   (alice)
        _depositTo    (100e18, alice, alice)
    {
        manager.mintFUSD(250_000e18, alice, alice);

        assertEq(fUSD.balanceOf(alice),      250_000e18);
        assertEq(manager.deposited(alice),   100e18);
        assertEq(manager.minted(alice),      250_000e18);
        assertEq(manager.collatRatio(alice), 1.6e18);
    }

    function test_mintFUSD_unlocked() public 
        _giveAssets   (delegate, 100e18)
        _startPrank   (delegate)
        _unlock       ()
        _setAssetPrice(4_000e8)
        _depositTo    (100e18, delegate, sigOwner)
    {
        manager.mintFUSD(250_000e18, sigOwner, address(this));

        assertEq(fUSD.balanceOf(address(this)), 250_000e18);
        assertEq(manager.deposited(sigOwner),   100e18);
        assertEq(manager.minted(sigOwner),      250_000e18);
        assertEq(manager.collatRatio(sigOwner), 1.6e18);
    }
}