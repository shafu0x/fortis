// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Script.sol";
import {ERC20} from "solady/src/tokens/ERC20.sol";

import {FUSD}        from "../src/FUSD.sol";
import {Manager}     from "../src/Manager.sol";
import {IOracle}     from "../interfaces/IOracle.sol";
import {Parameters}  from "../Parameters.sol";
import {WstETH_Mock} from "../mocks/WstEthMock.sol";
import {Oracle_Mock} from "../mocks/OracleMock.sol";

contract Deploy is Script, Parameters {
    ERC20   wsteth;
    IOracle oracle;

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

    function run() public returns (FUSD, Manager) {
        setUp();

        vm.startBroadcast(); // ----------------------

        FUSD    fUSD    = new FUSD();
        Manager manager = new Manager(
            fUSD,
            wsteth, 
            oracle
        );

        fUSD.transferOwnership(address(manager));

        vm.stopBroadcast(); // ----------------------------

        return (
            fUSD,
            manager
        );
    }
}