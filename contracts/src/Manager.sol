// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {ERC4626}           from "solmate/src/tokens/ERC4626.sol";
import {SafeTransferLib}   from "solmate/src/utils/SafeTransferLib.sol";
import {SafeCast}          from "@openzeppelin/utils/math/SafeCast.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";
import {ERC20}             from "solmate/src/tokens/ERC20.sol";

import {IOracle} from "../interfaces/IOracle.sol";

contract Manager is ERC4626 {
    using SafeTransferLib   for ERC20;
    using SafeCast          for int256;
    using FixedPointMathLib for uint256;

    uint public constant MIN_COLLAT_RATIO   = 1.3e18; // 130%
    uint public constant STALE_DATA_TIMEOUT = 24 hours;

    ERC20   public immutable fusd;
    ERC20   public immutable wstETH;
    IOracle public immutable oracle;

    mapping(address => bool)    public unlocked;
    mapping(address => address) public delegates;

    bytes32 public constant UNLOCK_TYPEHASH = keccak256(
        "Unlock(address owner,uint256 nonce,uint256 deadline,address delegate)"
    );

    mapping(address => uint) public deposits;
    mapping(address => uint) public minted;

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
        _withdraw(assets, shares, owner, receiver);
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
        _withdraw(assets, shares, owner, receiver);
    }

    function withdrawFrom(uint assets, address receiver, address owner) external {
        require(isUnlocked(owner));
        uint shares = previewWithdraw(assets);
        _withdraw(assets, shares, owner, receiver);
    }

    function redeemFrom(uint shares, address receiver, address owner) external {
        require(isUnlocked(owner));
        uint assets = previewRedeem(shares);
        _withdraw(assets, shares, owner, receiver);
    }

    function _withdraw(uint assets, uint shares, address owner, address receiver) internal {
        if (collatRatio(owner) < MIN_COLLAT_RATIO) revert("UNSUFFICIENT_COLLATERAL");
        _burn(owner, shares);
        asset.safeTransfer(receiver, assets);

        deposits[owner] -= assets;
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    function mintFUSD(uint amount, address owner, address receiver) external {
        require(isUnlocked(owner) || msg.sender == owner, "NOT_UNLOCKED_OR_OWNER");
        minted[owner] += amount;
        if (collatRatio(owner) < MIN_COLLAT_RATIO) revert("UNSUFFICIENT_COLLATERAL");
        fusd.mint(recipient, amount);
    }

    function collatRatio(address owner) public view returns (uint) {
        uint _minted = minted[owner];
        if (_minted == 0) return type(uint).max;
        uint totalValue = deposits[owner] * assetPrice() * 1e8;
        return totalValue.divWadDown(_minted);
    }

    function assetPrice() public view returns (uint256) {
        (, int256 answer,, uint256 updatedAt,) = oracle.latestRoundData();
        if (block.timestamp > updatedAt + STALE_DATA_TIMEOUT) revert("Stale data");
        return answer.toUint256();
    }

    function totalAssets() public view override returns (uint256) {
        return wstETH.balanceOf(address(this));
    }

    function unlock(
        address owner,
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
                owner,
                nonces[owner],  // Prevent replay attacks
                deadline,
                delegate
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", INITIAL_DOMAIN_SEPARATOR, structHash)
        );

        address signer = ecrecover(digest, v, r, s);

        require(signer == owner, "Invalid signature");

        nonces[owner]++;

        unlocked [owner] = true;
        delegates[owner] = delegate;
    }

    function lock(address owner) external {
        require(delegates[owner] == msg.sender);
        require(unlocked[owner]);
        unlocked [owner] = false;
        delegates[owner] = address(0);
    }

    function isUnlocked(address owner) public view returns (bool) {
        return unlocked[owner] && delegates[owner] == msg.sender;
    }

    function increaseNonce() external {
        nonces[msg.sender]++;
    }
}