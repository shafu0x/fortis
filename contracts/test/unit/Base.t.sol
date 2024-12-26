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
        deadline = 1735217468;
        v        = 28;
        r        = 0x18daa4369080e85c34532c8e04eff774ff1ad78f1610802ca4277dfb0b281a01;
        s        = 0x35285387d3e43ad6f695f7e8af7cea8cbf8af47fdb425a1f97ded272f0b214fc;
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
    modifier _deposit(uint amount, address owner) {
        manager.asset().approve(address(manager), amount);
        manager.deposit(amount, owner);
        _;
    }
    modifier _depositTo(uint amount, address owner, address recipient) {
        manager.asset().approve(address(manager), amount);
        manager.deposit(amount, recipient);
        _;
    }
    modifier _setAssetPrice(int price) {
        setAssetPrice(price);
        _;
    }
    modifier _setDeposited(address user, uint amount) {
        setDeposited(user, amount);
        _;
    }
    modifier _setMinted(address user, uint amount) {
        setMinted(user, amount);
        _;
    }
    modifier _mintFUSD(uint amount, address owner) {
        manager.mintFUSD(amount, owner, owner);
        _;
    }
    modifier _mintFUSDTo(uint amount, address owner, address receiver) {
        manager.mintFUSD(amount, owner, receiver);
        _;
    }
}