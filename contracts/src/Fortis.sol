// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import {ERC20} from "solmate/src/tokens/ERC20.sol";

contract Fortis is ERC20("Fortis", "FTS", 18) {
    constructor() {
        _mint(msg.sender, 1_000_000_000 * 10 ** 18); 
    }
}