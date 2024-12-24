// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {Base_Test} from "./Base.t.sol";

contract Unlock_Test is Base_Test {
    struct UnlockParams {
        address sigOwner;
        address delegate;
        uint256 deadline;
        uint8   v;
        bytes32 r;
        bytes32 s;
    }

    UnlockParams internal unlockParams;

    function setUp() public override {
        super.setUp();
        unlockParams = UnlockParams({
            sigOwner: 0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F,
            delegate: address(router),
            deadline: 1735043499,
            v:        28,
            r:        0xd8082fd33957ca7a95edfc396bd7f60845feb0512be55eeabfb252bcc0990665,
            s:        0x3911714f04783c5dd4f31ed7502e1e4a21c7b4152ab9a4c1415ae2b7a6768925
        });
    }

    function test_unlock() external {
        vm.startPrank(unlockParams.delegate);

        manager.unlock(
            unlockParams.sigOwner,
            unlockParams.delegate,
            unlockParams.deadline,
            unlockParams.v,
            unlockParams.r,
            unlockParams.s
        );

        vm.stopPrank();
    }

     function test_unlock_fail_delegateNotSender() external {
        vm.expectRevert("NOT_DELEGATE");
        manager.unlock(
            unlockParams.sigOwner,
            unlockParams.delegate,
            unlockParams.deadline,
            unlockParams.v,
            unlockParams.r,
            unlockParams.s
        );
    }

     function test_unlock_fail_invalidSignature() external prank(unlockParams.delegate) {
        vm.expectRevert("INVALID_SIGNATURE");
        manager.unlock(
            unlockParams.sigOwner,
            unlockParams.delegate,
            unlockParams.deadline,
            unlockParams.v + 1,
            unlockParams.r,
            unlockParams.s
        );
    }
}