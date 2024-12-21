// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import {Base_Test} from "./Base.t.sol";
import "forge-std/src/Test.sol";

contract Batching_Test is Base_Test {
    function test_batching() external {
        uint256 deadline;
        uint8   v;
        bytes32 r;
        bytes32 s;

        // TODO: give the manager a deterministic address
        if (address(manager) != 0xA8452Ec99ce0C64f20701dB7dD3abDb607c00496) {
            return;
        }

        if (block.chainid == 10) {
            deadline = 1734714403;
            v = 27;
            r = 0x44a58218751fa40a71ace3fca1a9c25b719e807b5f0aafaaeb608a37c7840d39;
            s = 0x34fdc6967c776567d84cb63b54beb8d36e194d5db34ee20c31ffd8436417de3d;
        } else if (block.chainid == 31337) {
            deadline = 1734744673;
            v = 27;
            r = 0x523f811c7e491f5c67730392bb80082db06baaeaa63017f2b6b040c2992be567;
            s = 0x17effecb7b28b791c733f26ef0da252270089e8b57cc0cced67601c937f75fc9;
        } else {
            revert("Unsupported Chain");
        }

        batcher.depositAndWithdraw(
            0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F,
            1e18,
            deadline,
            v,
            r,
            s
        );
    }
}