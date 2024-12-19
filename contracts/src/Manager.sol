// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import {ERC20} from "solady/src/tokens/ERC20.sol";

import {FUSD}    from "./FUSD.sol";
import {IOracle} from "../interfaces/IOracle.sol";

contract Manager {
    uint public constant MIN_COLLAT_RATIO = 1.3e18; // 130%

    FUSD    public immutable fusd;
    ERC20   public immutable wstETH;
    IOracle public immutable oracle;

    mapping(address => uint) public deposits;

    constructor(
        FUSD    _fusd,
        ERC20   _wstETH,
        IOracle _oracle
    ) {
        fusd   = _fusd;
        wstETH = _wstETH;
        oracle = _oracle;
    }

    function deposit(address recipient, uint amount) external {
        // Deposit ETH to mint fUSD
        // ...
    }
}