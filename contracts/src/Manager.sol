// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import {FUSD} from "./FUSD.sol";

contract Manager {
    FUSD public fusd;

    constructor() {
        fusd = new FUSD();
    }
}