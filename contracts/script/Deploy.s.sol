// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Script.sol";
import {ERC20}   from "solmate/src/tokens/ERC20.sol";

import {FUSD}        from "../src/FUSD.sol";
import {Manager}     from "../src/Manager.sol";
import {Fortis}      from "../src/Fortis.sol";
import {IOracle}     from "../interfaces/IOracle.sol";
import {IWstETH}     from "../interfaces/IWstETH.sol";
import {Router}      from "../src/Router.sol";
import {Parameters}  from "../Parameters.sol";
import {WstETH_Mock} from "../mocks/WstEth_Mock.sol";
import {Oracle_Mock} from "../mocks/Oracle_Mock.sol";

contract Deploy is Script, Parameters {
    IWstETH public wsteth;
    IOracle public assetOracle;
    IOracle public wstEth2stEthOracle;
    
    bytes32 public constant FORTIS_SALT  = keccak256("FORTIS_SALT");
    bytes32 public constant FUSD_SALT    = keccak256("FUSD_SALT");
    bytes32 public constant MANAGER_SALT = keccak256("MANAGER_SALT");
    bytes32 public constant ROUTER_SALT  = keccak256("ROUTER_SALT");

    function setUp() public {
        uint chainId = block.chainid;
        console.log("Deploying on Chain:", chainId);

        if (chainId == 10) {
            wsteth             = IWstETH(OPTIMISM_WSTETH);
            assetOracle        = IOracle(OPTIMISM_ORACLE_WSTETH_USD);
            wstEth2stEthOracle = IOracle(OPTIMISM_ORACLE_WSTETH_STETH);

            vm.createSelectFork(vm.envString("OPTIMISM_INFURA_URL"));
            vm.rollFork        (OPTIMISM_FORK_BLOCK_NUMBER);
        } else if (chainId == 31337) {
            wsteth             = IWstETH(address(new WstETH_Mock()));
            assetOracle        = new Oracle_Mock(1000e8);
            wstEth2stEthOracle = new Oracle_Mock(1000e8);
        } else {
            revert("Unsupported Chain");
        }
    }

    function run() public returns (Fortis, FUSD, Manager, Router) {
        setUp();

        vm.startBroadcast(); // ----------------------

        Fortis  fortis  = new Fortis(OWNER);
        FUSD    fUSD    = new FUSD(OWNER);
        Manager manager = new Manager(
            fUSD,
            wsteth,
            assetOracle,
            wstEth2stEthOracle,
            OWNER
        );

        Router router = new Router(manager);

        vm.stopBroadcast(); // ----------------------------

        return (
            fortis,
            fUSD,
            manager,
            router
        );
    }
}
