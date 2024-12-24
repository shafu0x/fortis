// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {Deploy}     from "../../script/Deploy.s.sol";
import {Fortis}     from "../../src/Fortis.sol";
import {FUSD}       from "../../src/FUSD.sol";
import {Manager}    from "../../src/Manager.sol";
import {Router}     from "../../src/Router.sol";
import {Parameters} from "../../Parameters.sol";

contract Base_Test is Test, Parameters {
    using stdStorage for StdStorage;

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
        stdstore
            .target(address(manager))
            .sig("unlocked(address)")
            .with_key(user)
            .depth(0)
            .checked_write(true);

        stdstore
            .target(address(manager))
            .sig("delegates(address)")
            .with_key(user)
            .depth(0)
            .checked_write(delegate);
    }

    function setOraclePrice() public {

    }
}