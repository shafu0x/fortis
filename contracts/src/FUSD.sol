// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import {ERC20}   from "solady/src/tokens/ERC20.sol";
import {Ownable} from "solady/src/auth/Ownable.sol";

contract FUSD is Ownable, ERC20 {
    constructor() { _initializeOwner(msg.sender); }

    function name() public pure override returns (string memory) {
        return "Fortis USD";
    }
    function symbol() public pure override returns (string memory) {
        return "fUSD";
    }
}