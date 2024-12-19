// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import {ERC20}   from "solady/src/tokens/ERC20.sol";
import {Ownable} from "solady/src/auth/Ownable.sol";

contract WstETH_Mock is Ownable, ERC20 {
    constructor() { _initializeOwner(msg.sender); }

    function name() public pure override returns (string memory) {
        return "Wrapped stETH";
    }
    function symbol() public pure override returns (string memory) {
        return "wstETH";
    }
    function mint(address recipient, uint amount) external {
        _mint(recipient, amount);
    }
    function burn(address account, uint amount) external {
        _burn(account, amount);
    }
}