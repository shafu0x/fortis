// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import {Base_Test} from "./BaseTest.t.sol";
import "forge-std/src/Test.sol";
import {Action} from "../src/Manager.sol";

interface IManager {
    struct Action {
        uint8 actionType;
        uint256 amount;
    }
}

contract Batching_Test is Base_Test {
    function test_batching() external {
        console.log("fUSD:", address(fUSD));

        Action[] memory actions = new Action[](2);
        actions[0] = Action({actionType: 0, amount: 100});
        actions[1] = Action({actionType: 1, amount: 50});

        manager.executeBatch(
            0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F,
            actions,
            0,
            1734697044, // 1 hour from now
            27,
            0xf0e4b2a31be5592e661bcd856698c3fa825eb393e57bf948e790c59b8f935126,
            0x413aea272b303ffd73e91cea9758243af347dc937e52e0e7872eeab79e11c566
        );
    }
}