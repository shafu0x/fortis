// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";
import {Manager} from "./Manager.sol";

contract Router {
    Manager public manager;

    constructor(Manager _manager) {
        manager = _manager;
    }

    function depositAndWithdraw(
        address recipient,
        uint amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        manager.unlock(
            recipient,
            address(this),
            deadline,
            v,
            r,
            s
        );

        // manager.depositFor(recipient, amount);
        // manager.withdrawFor(recipient, 100);
        // manager.withdrawFor(recipient, 50);

        manager.lock(recipient);
    }
}