// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {Base_Test} from "./Base.t.sol";

contract Liquidate_Test is Base_Test {
    function test_liquidate() public 
        _giveAssets   (alice, 100e18) 
        _setAssetPrice(4_000e8)
        _startPrank   (alice)
        _depositTo    (1e18, alice, alice)
        _mintFUSD     (1000e18, alice, alice)
        _setAssetPrice(1_200e8)
    {
        manager.liquidate(alice, 200e18, address(this));
    }
}