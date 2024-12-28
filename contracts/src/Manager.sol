// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {ERC4626}           from "solmate/src/tokens/ERC4626.sol";
import {SafeTransferLib}   from "solmate/src/utils/SafeTransferLib.sol";
import {SafeCast}          from "@openzeppelin/utils/math/SafeCast.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";
import {ERC20}             from "solmate/src/tokens/ERC20.sol";
import {Owned}             from "solmate/src/auth/Owned.sol";
import {ReentrancyGuard}   from "solmate/src/utils/ReentrancyGuard.sol";

import {IOracle} from "../interfaces/IOracle.sol";
import {IWstETH} from "../interfaces/IWstETH.sol";
import {Errors}  from "../libraries/ErrorsLib.sol";
import {FUSD}    from "./FUSD.sol";

contract Manager is ERC4626, Owned, ReentrancyGuard {
    using SafeTransferLib   for ERC20;
    using SafeCast          for int256;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                            CONSTANTS
    //////////////////////////////////////////////////////////////*/
    uint public constant MIN_COLLAT_RATIO        = 1.3e18;   // 130%
    uint public constant PERFORMANCE_FEE_BPS     = 1;        // 0.01%
    uint public constant WITHDRAWAL_FEE_BPS      = 10;       // 0.1%
    uint public constant LIQUIDATION_FEE_BPS     = 100;      // 1%
    uint public constant LIQUIDATION_PENALTY_BPS = 1100;     // 110%
    uint public constant STALE_DATA_TIMEOUT      = 24 hours;

    bytes32 public constant UNLOCK_TYPEHASH = keccak256(
        "Unlock(address owner,uint256 nonce,uint256 deadline,address delegate)"
    );
    uint256 internal immutable UNLOCK_INITIAL_CHAIN_ID;
    bytes32 internal immutable UNLOCK_INITIAL_DOMAIN_SEPARATOR;

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL CONTRACTS
    //////////////////////////////////////////////////////////////*/
    FUSD    public immutable fusd;
    ERC20   public immutable wstETH;
    IOracle public immutable assetOracle;
    IOracle public immutable wstEth2stEthOracle;

    /*//////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/
    address public feeReceiver;
    uint    public lastVaultBalanceWstETH;
    uint    public lastStEthPerWstEth;

    mapping(address => uint)    public deposited;
    mapping(address => uint)    public minted;
    mapping(address => bool)    public unlocked;
    mapping(address => address) public delegates;
    mapping(address => uint)    public unlockNonces;

    event Liquidate(address indexed owner, address indexed liquidator, uint amount, uint wstEthToSeize, uint fee);

    constructor(
        FUSD    _fusd,
        ERC20   _wstETH,
        IOracle _assetOracle,
        IOracle _wstEth2stEthOracle,
        address _owner
    ) Owned  (_owner) 
      ERC4626(_wstETH, "Fortis wstETH", "fwstETH") {
        fusd               = _fusd;
        wstETH             = _wstETH;
        assetOracle        = _assetOracle;
        wstEth2stEthOracle = _wstEth2stEthOracle;
        feeReceiver        = _owner;

        lastVaultBalanceWstETH = wstETH.balanceOf(address(this));
        lastStEthPerWstEth     = wstEth2stEth();

        UNLOCK_INITIAL_CHAIN_ID         = block.chainid;
        UNLOCK_INITIAL_DOMAIN_SEPARATOR = _computeUnlockDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier harvestBefore() {
        _harvestYield();
        _;
    }
    modifier onlyDelegate(address owner) {
        require(unlocked[owner] && delegates[owner] == msg.sender, Errors.NOT_DELEGATE);
        _;
    }
    modifier onlyOwnerOrDelegate(address owner) {
        require(
            msg.sender == owner || (unlocked[owner] && delegates[owner] == msg.sender),
            Errors.NOT_OWNER_OR_DELEGATE
        );
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            ERC-4626
    //////////////////////////////////////////////////////////////*/
    function deposit(uint assets, address receiver)
        public
        override
        harvestBefore
        nonReentrant
        returns (uint shares)
    {
        require((shares = previewDeposit(assets)) != 0, Errors.ZERO_SHARES);
        _deposit(assets, shares, receiver);
    }

    function mint(uint shares, address receiver)
        public
        override
        harvestBefore
        nonReentrant
        returns (uint assets)
    {
        assets = previewMint(shares);
        _deposit(assets, shares, receiver);
    }

    function _deposit(uint assets, uint shares, address receiver) internal {
        asset.safeTransferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);

        deposited[receiver] += assets; // Only diff to the solmate ERC4626
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function withdraw(uint assets, address receiver, address owner)
        public
        override
        harvestBefore
        nonReentrant
        returns (uint shares)
    {
        shares = previewWithdraw(assets);
        if (msg.sender != owner) {
            uint allowed = allowance[owner][msg.sender];
            if (allowed != type(uint).max) allowance[owner][msg.sender] = allowed - shares;
        }
        _withdraw(assets, shares, owner, receiver);
    }

    function redeem(uint shares, address receiver, address owner)
        public
        override
        harvestBefore
        nonReentrant
        returns (uint assets)
    {
        if (msg.sender != owner) {
            uint allowed = allowance[owner][msg.sender]; 
            if (allowed != type(uint).max) allowance[owner][msg.sender] = allowed - shares;
        }
        require((assets = previewRedeem(shares)) != 0, Errors.ZERO_ASSETS);
        _withdraw(assets, shares, owner, receiver);
    }

    function withdrawFrom(uint assets, address receiver, address owner) 
        external         
        harvestBefore
        nonReentrant 
        onlyDelegate(owner)
    {
        uint shares = previewWithdraw(assets);
        _withdraw(assets, shares, owner, receiver);
    }

    function redeemFrom(uint shares, address receiver, address owner) 
        external 
        harvestBefore
        nonReentrant 
        onlyDelegate(owner)
    {
        uint assets = previewRedeem(shares);
        _withdraw(assets, shares, owner, receiver);
    }

    function _withdraw(uint assets, uint shares, address owner, address receiver) internal {
        uint fee          = assets.mulDivDown(WITHDRAWAL_FEE_BPS, 10_000);
        uint netAssets    = assets - fee;
        deposited[owner] -= assets;

        if (collatRatio(owner) < MIN_COLLAT_RATIO) revert(Errors.INSUFFICIENT_COLLATERAL);

        _burn(owner, shares);

        asset.safeTransfer(feeReceiver, fee);
        asset.safeTransfer(receiver   , netAssets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /*//////////////////////////////////////////////////////////////
                                FUSD
    //////////////////////////////////////////////////////////////*/
    function mintFUSD(uint amount, address owner, address receiver) 
        external 
        nonReentrant
        harvestBefore 
        onlyOwnerOrDelegate(owner)
    {
        minted[owner] += amount;
        if (collatRatio(owner) < MIN_COLLAT_RATIO) revert(Errors.INSUFFICIENT_COLLATERAL);
        fusd.mint(receiver, amount);
    }

    function burnFUSD(uint amount, address owner) 
        external 
        nonReentrant
        harvestBefore 
        onlyOwnerOrDelegate(owner)
    {
        require((unlocked[owner] && delegates[owner] == msg.sender) || msg.sender == owner, Errors.NOT_OWNER_OR_DELEGATE);
        fusd.burn(owner, amount);
        minted[owner] -= amount;
    }

    function collatRatio(address owner) public view returns (uint) {
        uint _minted = minted[owner];
        if (_minted == 0) return type(uint).max;
        uint totalValue = deposited[owner] * assetPrice() / 1e8;
        return totalValue.divWadDown(_minted);
    }

    function assetPrice() public view returns (uint) {
        (, int answer,, uint updatedAt,) = assetOracle.latestRoundData();
        if (block.timestamp > updatedAt + STALE_DATA_TIMEOUT) revert(Errors.STALE_DATA);
        return answer.toUint256();
    }

    function wstEth2stEth() public view returns (uint) {
        (, int answer,, uint updatedAt,) = wstEth2stEthOracle.latestRoundData();
        if (block.timestamp > updatedAt + STALE_DATA_TIMEOUT) revert(Errors.STALE_DATA);
        return answer.toUint256();
    }

    function totalAssets() public view override returns (uint) {
        return wstETH.balanceOf(address(this));
    }

    function liquidate(address owner, uint amount, address receiver) 
        external
        nonReentrant
    {
        require(collatRatio(owner) < MIN_COLLAT_RATIO, Errors.NOT_UNDERCOLLATERIZED);

        uint debt = minted[owner];
        if (amount > debt) {
            amount = debt; 
        }
        require(amount > 0, Errors.NO_DEBT_TO_REPAY);

        uint price = assetPrice(); 
        uint wstEthToSeize = amount
            .mulDivDown(LIQUIDATION_PENALTY_BPS, 10000)
            .mulDivDown(1e8, price);

        uint wstEthBalance = deposited[owner];
        if (wstEthToSeize > wstEthBalance) {
            wstEthToSeize = wstEthBalance;
        }

        uint feeInWstEth      = wstEthToSeize.mulDivDown(LIQUIDATION_FEE_BPS, 10_000);
        uint netWstEthToSeize = wstEthToSeize - feeInWstEth;

        minted   [owner] = debt          - amount;
        deposited[owner] = wstEthBalance - wstEthToSeize;

        fusd.burn(msg.sender, amount);

        asset.safeTransfer(receiver   , netWstEthToSeize);
        asset.safeTransfer(feeReceiver, feeInWstEth);

        emit Liquidate(owner, msg.sender, amount, wstEthToSeize, feeInWstEth);
    }

    function _harvestYield() internal {
        uint currentRatio = wstEth2stEth();

        if (currentRatio <= lastStEthPerWstEth) { return; }

        uint oldBalance = lastVaultBalanceWstETH;
        if (oldBalance == 0) {
            lastStEthPerWstEth = currentRatio;
            return;
        }

        uint ratioDiff     = currentRatio - lastStEthPerWstEth;
        uint yieldInStEth  = oldBalance * ratioDiff;
        uint yieldInWstEth = yieldInStEth / currentRatio;

        uint feeInWstEth = (yieldInWstEth * PERFORMANCE_FEE_BPS) / 10_000;
        if (feeInWstEth > 0) {
            uint _totalSupply = totalSupply;
            uint _totalAssets = totalAssets();

            if (_totalSupply > 0 && _totalAssets > 0) {
                uint feeShares = feeInWstEth.mulDivDown(_totalSupply, _totalAssets);
                if (feeShares > 0) { _mint(feeReceiver, feeShares); }
            }
        }

        lastVaultBalanceWstETH = wstETH.balanceOf(address(this));
        lastStEthPerWstEth     = currentRatio;
    }

    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        feeReceiver = _feeReceiver;
    }

    /*//////////////////////////////////////////////////////////////
                                  LOCK
    //////////////////////////////////////////////////////////////*/
    function unlock(
        address owner,
        address delegate,
        uint256 deadline,
        uint8   v,
        bytes32 r,
        bytes32 s
    ) external {
        require(delegate == msg.sender,      Errors.NOT_DELEGATE);
        require(block.timestamp <= deadline, Errors.DEADLINE_EXPIRED);

        bytes32 structHash = keccak256(
            abi.encode(
                UNLOCK_TYPEHASH,
                owner,
                unlockNonces[owner],  // Prevent replay attacks
                deadline,
                delegate
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", UNLOCK_DOMAIN_SEPARATOR(), structHash)
        );

        address signer = ecrecover(digest, v, r, s);

        require(signer == owner, Errors.INVALID_SIGNATRURE);

        unlockNonces[owner]++;

        unlocked [owner] = true;
        delegates[owner] = delegate;
    }

    function lock(address owner) external {
        if (msg.sender == owner) {
            unlocked [owner] = false;
            delegates[owner] = address(0);
        } else if (delegates[owner] == msg.sender) {
            unlocked [owner] = false;
            delegates[owner] = address(0);
        } else {
            revert(Errors.NOT_OWNER_OR_DELEGATE);
        }
    }

    function _computeUnlockDomainSeparator() internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("ManagerUnlock")), 
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }

    function UNLOCK_DOMAIN_SEPARATOR() public view returns (bytes32) {
        if (block.chainid == UNLOCK_INITIAL_CHAIN_ID) {
            return UNLOCK_INITIAL_DOMAIN_SEPARATOR;
        }
        return _computeUnlockDomainSeparator();
    }
}