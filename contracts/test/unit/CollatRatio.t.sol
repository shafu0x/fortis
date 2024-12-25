// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {Base_Test} from "./Base.t.sol";

contract CollatRatio_Test is Base_Test {
    function test_collatRatio() public {
        setAssetPrice(4_000e8);
        setDeposited (alice, 100e18);
        setMinted    (alice, 250_000e18);

        assertEq(manager.collatRatio(alice), 1.6e18);

        setAssetPrice(3_500e8);
        setDeposited (alice, 100e18);
        setMinted    (alice, 250_000e18);

        assertEq(manager.collatRatio(alice), 1.4e18);
    }

    function test_collatRatio_nonMinted() public view {
        assertEq(manager.collatRatio(alice), type(uint).max);
    }
}