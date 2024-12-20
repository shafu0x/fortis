// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import {Test} from "forge-std/src/Test.sol";

import {Deploy} from "../script/Deploy.s.sol";

contract Deployment_Test is Test {
    function test_deployment() external {
        Deploy deploy = new Deploy();
        deploy.run();
    }
}