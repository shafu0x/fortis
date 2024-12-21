// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Script.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";

import {FUSD}        from "../src/FUSD.sol";
import {Manager}     from "../src/Manager.sol";
import {IOracle}     from "../interfaces/IOracle.sol";
import {Router}      from "../src/Router.sol";
import {Parameters}  from "../Parameters.sol";
import {WstETH_Mock} from "../mocks/WstEth_Mock.sol";
import {Oracle_Mock} from "../mocks/Oracle_Mock.sol";

contract Deploy is Script, Parameters {
    ERC20   wsteth;
    IOracle oracle;
    Router  router;

    function setUp() public {
        uint chainId = block.chainid;
        console.log("Deploying on Chain:", block.chainid);

        if (chainId == 10) {
            wsteth = ERC20  (OPTIMISM_WSTETH);
            oracle = IOracle(OPTIMISM_ORACLE_WSTETH_USD);

            vm.createSelectFork(vm.envString("OPTIMISM_INFURA_URL"));
            vm.rollFork        (OPTIMISM_FORK_BLOCK_NUMBER);
        } else if (chainId == 31337) {
            wsteth = new WstETH_Mock();
            oracle = new Oracle_Mock(1000e8);
        } else {
            revert("Unsupported Chain");
        }
    }

    function run() public returns (FUSD, Manager, Router) {
        setUp();

        vm.startBroadcast(); // ----------------------

        FUSD    fUSD    = new FUSD();
        Manager manager = new Manager(
            fUSD,
            wsteth, 
            oracle,
            address(0)
        );

        fUSD.transferOwnership(address(manager));

        router = new Router(manager);

        vm.stopBroadcast(); // ----------------------------

        return (
            fUSD,
            manager,
            router
        );
    }
}