// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {ERC20} from "solady/src/tokens/ERC20.sol";

import {FUSD}    from "./FUSD.sol";
import {IOracle} from "../interfaces/IOracle.sol";

struct Action {
    uint8 actionType;   // For example: 0 = deposit, 1 = withdraw
    uint256 amount;
}

contract Manager {
    uint public constant MIN_COLLAT_RATIO = 1.3e18; // 130%

    struct BatchAuthorization {
        address owner;
        Action[] actions;
        uint256 nonce;
        uint256 deadline;
    }

    mapping(address => uint256) public nonces;
    mapping(address => bool)    public unlocked;

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant ACTION_TYPEHASH = keccak256("Action(uint8 actionType,uint256 amount)");
    bytes32 public constant BATCH_TYPEHASH = keccak256(
        "BatchAuthorization(address owner,Action[] actions,uint256 nonce,uint256 deadline)Action(uint8 actionType,uint256 amount)"
    );
    bytes32 public constant WITHDRAW_FOR_TYPEHASH = keccak256("WithdrawFor(address from,uint256 amount,uint256 deadline)");
    bytes32 public constant UNLOCK_TYPEHASH = keccak256(
        "Unlock(address user,uint256 nonce,uint256 deadline)"
    );

    FUSD    public immutable fusd;
    ERC20   public immutable wstETH;
    IOracle public immutable oracle;

    mapping(address => uint) public deposits;

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

    function executeBatch(
        address owner,
        Action[] calldata actions,
        uint256 nonce,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(block.timestamp <= deadline, "Signature expired");
        require(nonce == nonces[owner], "Invalid nonce");

        // Compute the struct hash
        bytes32 structHash = _hashBatch(owner, actions, nonce, deadline);

        // Compute the digest
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
        );

        // Recover the signer
        address signer = ecrecover(digest, v, r, s);
        require(signer == owner, "Invalid signature");

        // Increment nonce to prevent replay
        nonces[owner]++;

        // Execute all actions
        for (uint256 i = 0; i < actions.length; i++) {
            _executeAction(owner, actions[i]);
        }
    }

    function _executeAction(address owner, Action memory action) internal {
        if (action.actionType == 0) {
            // Deposit logic here
            // For example, if this manager is integrated into your stablecoin contract:
            // _deposit(owner, action.amount);
        } else if (action.actionType == 1) {
            // Withdraw logic here
            // _withdraw(owner, action.amount);
        } else {
            revert("Unknown action type");
        }
    }

    function _hashBatch(
        address owner,
        Action[] calldata actions,
        uint256 nonce,
        uint256 deadline
    ) internal pure returns (bytes32) {
        bytes32 actionsHash = _hashActions(actions);
        return keccak256(
            abi.encode(
                BATCH_TYPEHASH,
                owner,
                actionsHash,
                nonce,
                deadline
            )
        );
    }

    function _hashActions(Action[] calldata actions) internal pure returns (bytes32) {
        bytes32[] memory actionHashes = new bytes32[](actions.length);
        for (uint256 i = 0; i < actions.length; i++) {
            actionHashes[i] = keccak256(
                abi.encode(
                    ACTION_TYPEHASH,
                    actions[i].actionType,
                    actions[i].amount
                )
            );
        }

        return keccak256(abi.encodePacked(actionHashes));
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

        unlocked[user] = true;
    }

    function lock(address user) external {
        unlocked[user] = false;
    }
}