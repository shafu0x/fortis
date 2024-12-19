// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Script.sol";

import {FUSD}    from "../src/FUSD.sol";
import {Manager} from "../src/Manager.sol";

contract Deploy is Script {
    function run() public returns (address, address) {
        FUSD    fUSD    = new FUSD();
        Manager manager = new Manager();

        fUSD.transferOwnership(address(manager));

        return (
            address(fUSD),
            address(manager)
        );
    }
}