// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {Owned} from "solmate/src/auth/Owned.sol";

contract FUSD is Owned(msg.sender), ERC20("Fortis USD", "fUSD", 18) {
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}