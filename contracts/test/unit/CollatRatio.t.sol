// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {Base_Test} from "./Base.t.sol";

contract CollatRatio_Test is Base_Test {
    function test_collatRatio_180Percent() public
        _setAssetPrice(4_500e8)
        _setDeposited (alice, 100e18)
        _setMinted    (alice, 250_000e18)
    {
        assertEq(manager.collatRatio(alice), 1.8e18);
    }

    function test_collatRatio_160Percent() public
        _setAssetPrice(4_000e8)
        _setDeposited (alice, 100e18)
        _setMinted    (alice, 250_000e18)
    {
        assertEq(manager.collatRatio(alice), 1.6e18);
    }

    function test_collatRatio_140Percent() public
        _setAssetPrice(3_500e8)
        _setDeposited (alice, 100e18)
        _setMinted    (alice, 250_000e18)
    {
        assertEq(manager.collatRatio(alice), 1.4e18);
    }

    function test_collatRatio_120Percent() public
        _setAssetPrice(3_000e8)
        _setDeposited (alice, 100e18)
        _setMinted    (alice, 250_000e18)
    {
        assertEq(manager.collatRatio(alice), 1.2e18);
    }

    function test_collatRatio_nonMinted() public view {
        assertEq(manager.collatRatio(alice), type(uint).max);
    }
}