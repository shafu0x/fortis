// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {Deploy}      from "../../script/Deploy.s.sol";
import {Fortis}      from "../../src/Fortis.sol";
import {FUSD}        from "../../src/FUSD.sol";
import {Manager}     from "../../src/Manager.sol";
import {Router}      from "../../src/Router.sol";
import {Oracle_Mock} from "../../mocks/Oracle_Mock.sol";
import {Parameters}  from "../../Parameters.sol";

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

    address sigOwner;
    address delegate;
    uint256 deadline;
    uint8   v;
    bytes32 r;
    bytes32 s;

    function setUp() public virtual {
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

        // TODO: refactor this
        vm.prank(fUSD.owner());
        fUSD.transferOwnership(address(manager));

        deployCodeTo(
            "Router.sol:Router",
            abi.encode(address(manager)),
            ROUTER_DETERMINISTIC_ADDRESS
        );

        router = Router(ROUTER_DETERMINISTIC_ADDRESS);

        alice = makeAddr("alice");
        bob   = makeAddr("bob");

        // Signature is generated with a js script
        sigOwner = 0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F;
        delegate = address(router);
        deadline = 1735043499;
        v        = 28;
        r        = 0xd8082fd33957ca7a95edfc396bd7f60845feb0512be55eeabfb252bcc0990665;
        s        = 0x3911714f04783c5dd4f31ed7502e1e4a21c7b4152ab9a4c1415ae2b7a6768925;
    }

    function setAssetPrice(int price) public {
        Oracle_Mock(address(manager.assetOracle())).setPrice(price);
    }

    function setDeposited(address user, uint amount) public {
        stdstore
            .target(address(manager))
            .sig("deposited(address)")
            .with_key(user)
            .depth(0)
            .checked_write(amount);
    }

    function setMinted(address user, uint amount) public {
        stdstore
            .target(address(manager))
            .sig("minted(address)")
            .with_key(user)
            .depth(0)
            .checked_write(amount);
    }

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier _unlock() {
        manager.unlock(
            sigOwner,
            delegate,
            deadline,
            v,
            r,
            s
        );
        _;
    }

    modifier _lock() {
        manager.lock(sigOwner);
        _;
    }

    modifier _giveAssets(address recipient, uint amount) {
        deal(address(manager.asset()), recipient, amount);
        _;
    }

    modifier _startPrank(address user) {
        vm.startPrank(user);
        _;
    }

    modifier _stopPrank() {
        vm.stopPrank();
        _;
    }

    modifier _depositTo(address owner, address recipient, uint amount) {
        vm.startPrank(owner);

        manager.asset().approve(address(manager), amount);
        manager.deposit(amount, recipient);
        _;

        vm.stopPrank();
    }

    modifier _setAssetPrice(int price) {
        setAssetPrice(price);
        _;
    }
}