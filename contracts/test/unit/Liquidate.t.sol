// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";
import {Errors} from "../../src/libraries/ErrorsLib.sol";

import {Base_Test} from "./Base.t.sol";

contract Liquidate_Test is Base_Test {
    function test_liquidate() public 
        _giveAssets   (alice, 100e18) 
        _setAssetPrice(4_000e8)
        _startPrank   (alice)
        _deposit      (1e18, alice)
        _mintFUSD     (1000e18, alice)
        _setAssetPrice(1_200e8)
    {
        manager.liquidate(alice, 200e18, address(this));

        assertEq(manager.minted(alice), 1000e18 - 200e18);
    }

    function test_liquidate_all() public 
        _giveAssets   (alice, 100e18) 
        _setAssetPrice(4_000e8)
        _startPrank   (alice)
        _deposit      (1e18, alice)
        _mintFUSD     (1000e18, alice)
        _setAssetPrice(1_200e8)
    {
        manager.liquidate(alice, 1000e18, address(this));

        assertEq(manager.minted(alice), 0);
    }

    function test_liquidate_fail_notUndercollaterized() public 
        _giveAssets   (alice, 100e18) 
        _setAssetPrice(4_000e8)
        _startPrank   (alice)
        _deposit      (1e18, alice)
        _mintFUSD     (1000e18, alice)
        _setAssetPrice(2_000e8)
    {
        expectRevert(Errors.NOT_UNDERCOLLATERIZED);
        manager.liquidate(alice, 200e18, address(this));
    }

    function test_liquidate_fail_noDebtToRepay() public 
        _giveAssets   (alice, 100e18) 
        _setAssetPrice(4_000e8)
        _startPrank   (alice)
        _deposit      (1e18, alice)
        _mintFUSD     (1000e18, alice)
        _setAssetPrice(1_200e8)
    {
        expectRevert(Errors.NO_DEBT_TO_REPAY);
        manager.liquidate(alice, 0, address(this));
    }
}