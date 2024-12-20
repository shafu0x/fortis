// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {ERC20} from "solady/src/tokens/ERC20.sol";

import {FUSD}    from "./FUSD.sol";
import {IOracle} from "../interfaces/IOracle.sol";

contract Manager {
    uint public constant MIN_COLLAT_RATIO = 1.3e18; // 130%

    mapping(address => uint256) public nonces;
    mapping(address => bool)    public unlocked;
    mapping(address => address) public delegates;

    FUSD    public immutable fusd;
    ERC20   public immutable wstETH;
    IOracle public immutable oracle;

    mapping(address => uint) public deposits;

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant UNLOCK_TYPEHASH = keccak256(
        "Unlock(address user,uint256 nonce,uint256 deadline)"
    );

    constructor(
        FUSD    _fusd,
        ERC20   _wstETH,
        IOracle _oracle
    ) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("MyStablecoinManager")), // Name of the domain
                keccak256(bytes("1")),                    // Version
                chainId,
                address(this)
            )
        );

        console.log(address(this));

        fusd   = _fusd;
        wstETH = _wstETH;
        oracle = _oracle;
    }

    function deposit(uint amount) external {
        _deposit(msg.sender, amount);
    }

    function withdraw(uint amount) external {
        _withdraw(msg.sender, amount);
    }

    function depositFor(address to, uint amount) external {
        require(unlocked[to]);
        _deposit(to, amount);
    }

    function withdrawFor(address from, uint amount) external {
        require(unlocked[from]);
        _withdraw(from, amount);
    }

    function _deposit(address to, uint amount) internal {}
    function _withdraw(address from, uint amount) internal {}

    function unlock(
        address user,
        address delegate,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(block.timestamp <= deadline, "Signature expired");

        bytes32 structHash = keccak256(
            abi.encode(
                UNLOCK_TYPEHASH,
                user,
                nonces[user],  // Prevent replay attacks
                deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
        );

        address signer = ecrecover(digest, v, r, s);

        require(signer == user, "Invalid signature");

        nonces[user]++;

        unlocked [user] = true;
        delegates[user] = delegate;
    }

    function lock(address user) external {
        unlocked [user] = false;
        delegates[user] = address(0);
    }

    function isUnlocked(address user) external view returns (bool) {
        return unlocked[msg.sender] && delegates[msg.sender] == user;
    }
}