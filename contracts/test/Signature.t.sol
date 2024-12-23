// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {Base_Test} from "./Base.t.sol";

contract Router_Test is Base_Test {
    function test_batching() external {
        uint256 deadline;
        uint8   v;
        bytes32 r;
        bytes32 s;

        console.log("Manager Address", address(manager));

        console.log("xXXXX");
        console.logBytes32(vm.load(address(manager), bytes32(uint(7))));
        vm.store(address(manager), bytes32(uint(7)), bytes32(uint(1)));
        console.log(manager.feeReceiver());

        address user = address(0x1234);

        uint256 mappingSlot = 10; // Replace with actual slot for `unlocked`

        // Calculate the storage key for the mapping
        bytes32 storageKey = keccak256(abi.encode(user, mappingSlot));

        // Use vm.store to set the mapping value
        vm.store(address(manager), storageKey, bytes32(uint256(1))); // 1 == true

        console.log(manager.unlocked(user));

        // TODO: give the manager a deterministic address
        if (address(manager) != 0xA8452Ec99ce0C64f20701dB7dD3abDb607c00496) {
            return;
        }

        if (block.chainid == 10) {
            deadline = 1734745325;
            v = 28;
            r = 0x7fa87cf4e373616cccf5d47685390e8ad2762fb1396a9ce0e8aa189d805799ec;
            s = 0x55ee27ff73088dd75347a0b0c79c2f3bd982026385a286a625654df7d3713302;
        } else if (block.chainid == 31337) {
            deadline = 1734745290;
            v = 27;
            r = 0xba93ae601bba92c85d8e613a1cb7ff49a4314cb52547daaa24f8b08f9d5b6a9c;
            s = 0x7675c0a08ae3c1448947ee329dcdbcb92a108920aff9692d5cf9d8311e89cff2;
        } else {
            revert("Unsupported Chain");
        }
    }
}