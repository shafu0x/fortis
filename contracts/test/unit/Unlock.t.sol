// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {Base_Test} from "./Base.t.sol";

contract Unlock_Test is Base_Test {
    function test_unlock() external 
        prank(delegate)
        unlock()
    {
        assertTrue(manager.isUnlocked(sigOwner));
    }

    function test_unlockAndLock() external
        prank(delegate)
        unlock()
        lock()
    {
        assertFalse(manager.isUnlocked(sigOwner));
    }

     function test_unlock_fail_delegateNotSender() external {
        vm.expectRevert("NOT_DELEGATE");
        manager.unlock(
            sigOwner,
            delegate,
            deadline,
            v,
            r,
            s
        );
    }

     function test_unlock_fail_invalidSignature() external prank(delegate) {
        vm.expectRevert("INVALID_SIGNATURE");
        manager.unlock(
            sigOwner,
            delegate,
            deadline,
            v + 1, // make the signature invalid
            r,
            s
        );
    }
}