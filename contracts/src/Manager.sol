// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {ERC4626}           from "solmate/src/tokens/ERC4626.sol";
import {SafeTransferLib}   from "solmate/src/utils/SafeTransferLib.sol";
import {SafeCast}          from "@openzeppelin/utils/math/SafeCast.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";
import {ERC20}             from "solmate/src/tokens/ERC20.sol";

import {IOracle} from "../interfaces/IOracle.sol";
import {IWstETH} from "../interfaces/IWstETH.sol";
import {FUSD}    from "./FUSD.sol";

contract Manager is ERC4626 {
    using SafeTransferLib   for ERC20;
    using SafeCast          for int256;
    using FixedPointMathLib for uint256;

    uint public constant MIN_COLLAT_RATIO        = 1.3e18; // 130%
    uint public constant STALE_DATA_TIMEOUT      = 24 hours;
    uint public constant PERFORMANCE_FEE_BPS     = 1;      // 0.01%
    uint public constant LIQUIDATION_PENALTY_BPS = 1100; // 110%

    FUSD    public immutable fusd;
    ERC20   public immutable wstETH;
    IOracle public immutable oracle;
    address public immutable feeReceiver;

    uint public lastVaultBalanceWstETH;
    uint public lastStEthPerWstEth;

    mapping(address => bool)    public unlocked;
    mapping(address => address) public delegates;

    bytes32 public constant UNLOCK_TYPEHASH = keccak256(
        "Unlock(address owner,uint256 nonce,uint256 deadline,address delegate)"
    );

    mapping(address => uint) public deposits;
    mapping(address => uint) public minted;

    event Liquidate(address indexed owner, address indexed liquidator, uint256 amount, uint256 wstEthToSeize);

    constructor(
        FUSD    _fusd,
        ERC20   _wstETH,
        IOracle _oracle,
        address _feeReceiver
    ) ERC4626(_wstETH, "Fortis wstETH", "fwstETH") {
        fusd        = _fusd;
        wstETH      = _wstETH;
        oracle      = _oracle;
        feeReceiver = _feeReceiver;

        lastVaultBalanceWstETH = _wstETH.balanceOf(address(this));
        lastStEthPerWstEth     = IWstETH(address(_wstETH)).stEthPerToken(); // TODO: refactor
    }

    modifier harvestBefore() {
        _harvestYield();
        _;
    }

    function deposit(uint256 assets, address receiver)
        public
        override
        harvestBefore
        returns (uint256 shares)
    {
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");
        _deposit(assets, shares, receiver);
    }

    function mint(uint256 shares, address receiver)
        public
        override
        harvestBefore
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
        harvestBefore
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
        harvestBefore
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
        if (collatRatio(owner) < MIN_COLLAT_RATIO) revert("INSUFFICIENT_COLLATERAL");
        _burn(owner, shares);
        asset.safeTransfer(receiver, assets);

        deposits[owner] -= assets;
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    function mintFUSD(uint amount, address owner, address receiver) external harvestBefore {
        require(isUnlocked(owner) || msg.sender == owner, "NOT_UNLOCKED_OR_OWNER");
        minted[owner] += amount;
        if (collatRatio(owner) < MIN_COLLAT_RATIO) revert("INSUFFICIENT_COLLATERAL");
        fusd.mint(receiver, amount);
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

    function totalAssets() public view override returns (uint) {
        return wstETH.balanceOf(address(this));
    }

    function liquidate(address owner, uint amount, address receiver) external {
        require(collatRatio(owner) < MIN_COLLAT_RATIO, "NOT_UNDERCOLLATERALIZED");

        uint debt = minted[owner];
        if (amount > debt) {
            amount = debt; 
        }
        require(amount > 0, "NO_DEBT_TO_REPAY");

        uint price = assetPrice(); 
        uint wstEthToSeize = amount
            .mulDivDown(LIQUIDATION_PENALTY_BPS, 10000)
            .mulDivDown(1e8, price);

        uint wstEthBalance = deposits[owner];
        if (wstEthToSeize > wstEthBalance) {
            wstEthToSeize = wstEthBalance;
        }

        minted[owner]   = debt - amount;
        deposits[owner] = wstEthBalance - wstEthToSeize;

        fusd.burn(msg.sender, amount);

        asset.safeTransfer(receiver, wstEthToSeize);

        emit Liquidate(owner, msg.sender, amount, wstEthToSeize);
    }

    function _harvestYield() internal {
        // 1) Check current ratio
        uint currentRatio = IWstETH(address(wstETH)).stEthPerToken(); // TODO: refactor

        // 2) If ratio has not increased, no yield to skim
        if (currentRatio <= lastStEthPerWstEth) {
            return; 
        }

        // 3) The old vault balance in wstETH
        uint oldBalance = lastVaultBalanceWstETH;
        if (oldBalance == 0) {
            // If the vault had 0 wstETH last time, no yield
            lastStEthPerWstEth = currentRatio;
            return;
        }

        // 4) stETH yield from ratio growth:
        //
        //    yieldInStEth = oldBalance * (currentRatio - lastStEthPerWstEth)
        //    yieldInWstEth = yieldInStEth / currentRatio
        //                  = oldBalance * [ (currentRatio - lastStEthPerWstEth) / currentRatio ]
        //                  = oldBalance * (1 - (lastStEthPerWstEth / currentRatio))
        //
        uint ratioDiff     = currentRatio - lastStEthPerWstEth;
        uint yieldInStEth  = oldBalance * ratioDiff;
        uint yieldInWstEth = yieldInStEth / currentRatio;

        // 5) The portion of that yield that is our fee
        uint feeInWstEth = (yieldInWstEth * PERFORMANCE_FEE_BPS) / 10_000;
        if (feeInWstEth > 0) {
            // 6) Convert that wstETH amount into vault shares at current share price
            //    sharePrice = totalAssets() / totalSupply
            //    so shares = feeInWstEth * totalSupply / totalAssets
            uint _totalSupply = totalSupply;
            uint _totalAssets = totalAssets();

            // Avoid edge cases if totalSupply == 0
            if (_totalSupply > 0 && _totalAssets > 0) {
                uint feeShares = feeInWstEth.mulDivDown(_totalSupply, _totalAssets);
                if (feeShares > 0) {
                    // Mint those shares to feeReceiver
                    _mint(feeReceiver, feeShares);
                }
            }
        }

        // 7) Update the ratio baseline
        lastStEthPerWstEth = currentRatio;
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