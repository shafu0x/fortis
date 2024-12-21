// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";

import {FUSD}    from "./FUSD.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {Lock}    from "./Lock.sol";

contract Manager is Lock, ERC20("Fortis wstETH", "fwstETH") {
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
        setDomainSeperator();

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

    function _deposit(address to, uint amount) internal {
        _mint(to, amount);
    }

    function _withdraw(address from, uint amount) internal {
        _burn(from, amount);
    }
}