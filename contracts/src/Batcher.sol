// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";
import {Manager} from "./Manager.sol";

contract Batcher {
    Manager public manager;

    constructor(Manager _manager) {
        manager = _manager;
    }

    function depositAndWithdraw(address recipient, uint amount) external {
        // here is the key do whatever you want
        manager.unlock(
            0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F,
            1734714403,
            27,
            0x44a58218751fa40a71ace3fca1a9c25b719e807b5f0aafaaeb608a37c7840d39,
            0x34fdc6967c776567d84cb63b54beb8d36e194d5db34ee20c31ffd8436417de3d
        );

        manager.depositFor(0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F, amount);
        manager.withdrawFor(0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F, 100);
        manager.withdrawFor(0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F, 50);

       // thats it
        manager.lock(0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F);
    }
}