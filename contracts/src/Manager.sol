// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {ERC4626}         from "solmate/src/tokens/ERC4626.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {SafeCast}        from "@openzeppelin/utils/math/SafeCast.sol";
import {ERC20}           from "solmate/src/tokens/ERC20.sol";

import {IOracle} from "../interfaces/IOracle.sol";

contract Manager is ERC4626 {
    using SafeTransferLib for ERC20;
    using SafeCast        for int256;

    uint public constant MIN_COLLAT_RATIO   = 1.3e18; // 130%
    uint public constant STALE_DATA_TIMEOUT = 24 hours;

    ERC20   public immutable fusd;
    ERC20   public immutable wstETH;
    IOracle public immutable oracle;

    mapping(address => bool)    public unlocked;
    mapping(address => address) public delegates;

    bytes32 public constant UNLOCK_TYPEHASH = keccak256(
        "Unlock(address user,uint256 nonce,uint256 deadline,address delegate)"
    );

    mapping(address => uint256) public deposits;

    constructor(
        ERC20   _fusd,
        ERC20   _wstETH,
        IOracle _oracle
    ) ERC4626(_fusd, "Fortis wstETH", "fwstETH") {
        fusd   = _fusd;
        wstETH = _wstETH;
        oracle = _oracle;
    }

    function deposit(uint256 assets, address receiver)
        public
        override
        returns (uint256 shares)
    {
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");
        _deposit(assets, shares, receiver);
    }

    function mint(uint256 shares, address receiver)
        public
        override
        returns (uint256 assets)
    {
        assets = previewMint(shares);
        _deposit(assets, shares, receiver);
    }

    function _deposit(uint assets, uint shares, address receiver) internal {
        asset.safeTransferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);

        deposits[receiver] += assets;
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function withdraw(uint256 assets, address receiver, address owner)
        public
        override
        returns (uint256 shares)
    {
        shares = previewWithdraw(assets);
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender];
            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }
        _withdraw(owner, receiver, assets, shares);
    }

    function redeem(uint256 shares, address receiver, address owner)
        public
        override
        returns (uint256 assets)
    {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; 
            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");
        _withdraw(owner, receiver, assets, shares);
    }

    function withdrawFrom(address from, uint assets, address receiver) external {
        require(isUnlocked(from));
        uint shares = previewWithdraw(assets);
        _withdraw(from, receiver, assets, shares);
    }

    function redeemFrom(address from, uint shares, address receiver) external {
        require(isUnlocked(from));
        uint assets = previewRedeem(shares);
        _withdraw(from, receiver, assets, shares);
    }

    function _withdraw(address owner, address receiver, uint assets, uint shares) internal {
        _burn(owner, shares);
        asset.safeTransfer(receiver, assets);

        deposits[owner] -= assets;
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    function totalAssets() public view override returns (uint256) {
        return wstETH.balanceOf(address(this));
    }

    function assetPrice() public view returns (uint256) {
        (, int256 answer,, uint256 updatedAt,) = oracle.latestRoundData();
        if (block.timestamp > updatedAt + STALE_DATA_TIMEOUT) revert("Stale data");
        return answer.toUint256();
    }

    function unlock(
        address user,
        address delegate,
        uint256 deadline,
        uint8   v,
        bytes32 r,
        bytes32 s
    ) external {
        require(delegate == msg.sender);
        require(block.timestamp <= deadline, "Signature expired");

        bytes32 structHash = keccak256(
            abi.encode(
                UNLOCK_TYPEHASH,
                user,
                nonces[user],  // Prevent replay attacks
                deadline,
                delegate
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", INITIAL_DOMAIN_SEPARATOR, structHash)
        );

        address signer = ecrecover(digest, v, r, s);

        require(signer == user, "Invalid signature");

        nonces[user]++;

        unlocked [user] = true;
        delegates[user] = delegate;
    }

    function lock(address user) external {
        require(delegates[user] == msg.sender);
        require(unlocked[user]);
        unlocked [user] = false;
        delegates[user] = address(0);
    }

    function isUnlocked(address user) public view returns (bool) {
        return unlocked[user] && delegates[user] == msg.sender;
    }

    function increaseNonce() external {
        nonces[msg.sender]++;
    }
}