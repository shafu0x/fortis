// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {Deploy}     from "../script/Deploy.s.sol";
import {Fortis}     from "../src/Fortis.sol";
import {FUSD}       from "../src/FUSD.sol";
import {Manager}    from "../src/Manager.sol";
import {Router}     from "../src/Router.sol";
import {Parameters} from "../Parameters.sol";

contract Base_Test is Test, Parameters {
    uint UNLOCKED_SLOT = 10; 
    uint DELEGATES_SLOT = 11; 

    Fortis  public fortis;
    FUSD    public fUSD;
    Manager public manager;
    Router  public router;

    function setUp() external {
        Deploy deploy = new Deploy();
        (fortis, fUSD, manager, router) = deploy.run();
    }

    function unlock(address user, address delegate) public {
        vm.store(address(manager), keccak256(abi.encode(user, UNLOCKED_SLOT)),  bytes32(uint256(1))); 
        vm.store(address(manager), keccak256(abi.encode(user, DELEGATES_SLOT)), bytes32(uint256(uint160(delegate)))); 
    }

    function setOraclePrice() public {

    }
}