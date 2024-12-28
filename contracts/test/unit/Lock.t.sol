// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";
import {Errors} from "../../libraries/ErrorsLib.sol";

import {Base_Test} from "./Base.t.sol";

contract Unlock_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////
                                 UNLOCK
    //////////////////////////////////////////////////////////////*/
    function test_unlock() external 
        _startPrank(delegate)
        _unlock()
    {
        assertTrue(manager.unlocked(sigOwner));
        assertTrue(manager.delegates(sigOwner) == delegate);
    }

     function test_unlock_fail_delegateNotSender() external {
        expectRevert(Errors.NOT_DELEGATE);
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
        _startPrank(delegate) 
    {
        expectRevert(Errors.INVALID_SIGNATRURE);
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
    function test_lock_asDelegate() external
        _startPrank(delegate)
        _unlock()
        _lock()
    {
        assertFalse(manager.unlocked(sigOwner));
        assertTrue (manager.delegates(sigOwner) == address(0));
    }

    function test_lock_asOwner() external
        _startPrank(delegate)
        _unlock()
        _startPrank(sigOwner)
        _lock()
    {
        assertFalse(manager.unlocked(sigOwner));
        assertTrue (manager.delegates(sigOwner) == address(0));
    }

    function test_lock_fail_notDelegateOrOwner() external
        _startPrank(delegate)
        _unlock()
        _stopPrank()
    {
        expectRevert(Errors.NOT_OWNER_OR_DELEGATE);
        manager.lock(sigOwner);
    }
}