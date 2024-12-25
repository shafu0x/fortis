// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {Base_Test} from "./Base.t.sol";

contract Deposit_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////
                                DEPOSIT
    //////////////////////////////////////////////////////////////*/
    function test_deposit() 
        public 
            _giveAssets(alice, 10e18) 
            _startPrank(alice) 
    {
        manager.asset().approve(address(manager), 10e18);
        manager.deposit(10e18, alice);

        assertEq(manager.deposited(alice), 10e18);
    }

    function test_deposit_fuzz(uint amount) 
        public 
            _giveAssets(alice, amount) 
            _startPrank(alice) 
    {
        vm.assume(amount != 0);

        manager.asset().approve(address(manager), amount);
        manager.deposit(amount, alice);

        assertEq(manager.deposited(alice), amount);
    }

    function test_deposit_forBob() 
        public 
            _giveAssets(alice, 10e18) 
            _startPrank(alice) 
    {
        assertEq(manager.deposited(bob), 0);

        manager.asset().approve(address(manager), 10e18);
        manager.deposit(10e18, bob);

        assertEq(manager.deposited(bob), 10e18);
    }

    function test_deposit_fuzz_forBob(uint amount) 
        public 
            _giveAssets(alice, amount) 
            _startPrank(alice) 
    {
        vm.assume(amount != 0);

        manager.asset().approve(address(manager), amount);
        manager.deposit(amount, bob);

        assertEq(manager.deposited(bob), amount);
    }

    /*//////////////////////////////////////////////////////////////
                                  MINT
    //////////////////////////////////////////////////////////////*/
    function test_mint() 
        public 
            _giveAssets(alice, 10e18) 
            _startPrank(alice) 
    {
        manager.asset().approve(address(manager), 10e18);
        manager.mint(10e18, alice);

        assertEq(manager.deposited(alice), 10e18);
    }

    function test_mint(uint amount) 
        public 
            _giveAssets(alice, amount) 
            _startPrank(alice) 
    {
        vm.assume(amount != 0);

        manager.asset().approve(address(manager), amount);
        manager.mint(amount, alice);

        assertEq(manager.deposited(alice), amount);
    }
}