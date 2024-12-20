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

        console.log(block.chainid);

        if (block.chainid == 10) {
            deadline = 1734714403;
            v = 27;
            r = 0x44a58218751fa40a71ace3fca1a9c25b719e807b5f0aafaaeb608a37c7840d39;
            s = 0x34fdc6967c776567d84cb63b54beb8d36e194d5db34ee20c31ffd8436417de3d;
        } else if (block.chainid == 31337) {
            deadline = 1734729304;
            v = 27;
            r = 0x7242d9b9f86dbe2f46939b7b44c95a7f4b9c4c93af13c15ed0b74d523c5accae;
            s = 0x42727dfab8675fd2d5f9f10a7542f457620716f83a5dfeea0d9ade92e7871266;
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