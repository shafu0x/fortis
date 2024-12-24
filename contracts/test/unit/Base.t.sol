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

    address constant MANAGER_DETERMINISTIC_ADDRESS = 0x1000000000000000000000000000000000000013;
    address constant ROUTER_DETERMINISTIC_ADDRESS  = 0x1000000000000000000000000000000000000014;

    Fortis  public fortis;
    FUSD    public fUSD;
    Manager public manager;
    Router  public router;

    address alice;
    address bob;

    function setUp() external {
        Deploy deploy = new Deploy();
        (fortis, fUSD, manager, router) = deploy.run();

        // we give the manager a deterministic address,
        // so we can generate a correct signature once.
        deployCodeTo(
            "Manager.sol:Manager",
            abi.encode(
                address(fUSD),
                address(manager.asset()),
                address(manager.assetOracle()),
                address(manager.wstEth2stEthOracle()),
                OWNER
            ),
            MANAGER_DETERMINISTIC_ADDRESS
        );

        manager = Manager(MANAGER_DETERMINISTIC_ADDRESS);

        deployCodeTo(
            "Router.sol:Router",
            abi.encode(address(manager)),
            ROUTER_DETERMINISTIC_ADDRESS
        );

        router = Router(ROUTER_DETERMINISTIC_ADDRESS);

        alice = makeAddr("alice");
        bob   = makeAddr("bob");
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

    modifier giveAssets(address recipient, uint amount) {
        deal(address(manager.asset()), recipient, 10e18);
        _;
    }

    modifier prank(address user) {
        vm.startPrank(user);
        _;
        vm.stopPrank();
    }

    modifier depositTo(address owner, address recipient, uint amount) {
        vm.startPrank(owner);

        manager.asset().approve(address(manager), 10e18);
        manager.deposit(amount, recipient);
        _;

        vm.stopPrank();
    }
}