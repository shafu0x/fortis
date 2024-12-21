// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import {Base_Test} from "./Base.t.sol";
import "forge-std/src/Test.sol";

contract Router_Test is Base_Test {
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
            deadline = 1734744763;
            v = 28;
            r = 0x512a140a2ce3e15c77eeea6cfbec369193fa3b1064c06f680a7fa4311e6022f9;
            s = 0x775469acba046d6ccd0e19327c57e7eab9d2d59031d737408ea2f5c1145a899a;
        } else if (block.chainid == 31337) {
            deadline = 1734744673;
            v = 27;
            r = 0x523f811c7e491f5c67730392bb80082db06baaeaa63017f2b6b040c2992be567;
            s = 0x17effecb7b28b791c733f26ef0da252270089e8b57cc0cced67601c937f75fc9;
        } else {
            revert("Unsupported Chain");
        }

        router.depositAndWithdraw(
            0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F,
            1e18,
            deadline,
            v,
            r,
            s
        );
    }
}