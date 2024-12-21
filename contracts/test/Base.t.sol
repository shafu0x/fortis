// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {Deploy}  from "../script/Deploy.s.sol";
import {Fortis}  from "../src/Fortis.sol";
import {FUSD}    from "../src/FUSD.sol";
import {Manager} from "../src/Manager.sol";
import {Router}  from "../src/Router.sol";

contract Base_Test is Test {
    Fortis  public fortis;
    FUSD    public fUSD;
    Manager public manager;
    Router  public router;

    function setUp() external {
        Deploy deploy = new Deploy();
        (fortis, fUSD, manager, router) = deploy.run();
    }
}