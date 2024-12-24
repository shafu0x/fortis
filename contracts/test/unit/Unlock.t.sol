// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {Base_Test} from "./Base.t.sol";

contract Unlock_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////
                                 UNLOCK
    //////////////////////////////////////////////////////////////*/
    function test_unlock() external 
        startPrank(delegate)
        unlock()
    {
        assertTrue(manager.isUnlocked(sigOwner));
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

     function test_unlock_fail_invalidSignature() external 
        startPrank(delegate) 
    {
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

    /*//////////////////////////////////////////////////////////////
                                  LOCK
    //////////////////////////////////////////////////////////////*/
    function test_lock() external
        startPrank(delegate)
        unlock()
        lock()
    {
        assertFalse(manager.isUnlocked(sigOwner));
    }

    function test_lock_fail_notDelegate() external
        startPrank(delegate)
        unlock()
        stopPrank()
    {
        vm.expectRevert("NOT_DELEGATE");
        manager.lock(sigOwner);
    }
}