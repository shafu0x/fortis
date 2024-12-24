// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {Base_Test} from "./Base.t.sol";

contract Unlock_Test is Base_Test {
    function test_unlock() external {
        address OWNER    = 0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F;
        address DELEGATE = address(router); 
        uint    DEADLINE = 1735043499;
        uint8   V        = 28;
        bytes32 R        = 0xd8082fd33957ca7a95edfc396bd7f60845feb0512be55eeabfb252bcc0990665;
        bytes32 S        = 0x3911714f04783c5dd4f31ed7502e1e4a21c7b4152ab9a4c1415ae2b7a6768925;

        vm.startPrank(DELEGATE);

        manager.unlock(
            OWNER,
            DELEGATE,
            DEADLINE,
            V,
            R,
            S
        );

        vm.stopPrank();
    }
}