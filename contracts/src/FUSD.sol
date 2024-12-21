// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import {ERC20}   from "solmate/src/tokens/ERC20.sol";
import {Ownable} from "solady/src/auth/Ownable.sol";

contract FUSD is Ownable, ERC20("Fortis USD", "fUSD", 18) {
    constructor() { _initializeOwner(msg.sender); }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}