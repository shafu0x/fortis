// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import {ERC20}   from "solmate/src/tokens/ERC20.sol";
import {Ownable} from "solady/src/auth/Ownable.sol";

contract WstETH_Mock is Ownable, ERC20("Wrapped stETH", "wstETH", 18) {
    constructor() { _initializeOwner(msg.sender); }

    function mint(address recipient, uint amount) external {
        _mint(recipient, amount);
    }
    function burn(address account, uint amount) external {
        _burn(account, amount);
    }
}