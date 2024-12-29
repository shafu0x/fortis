// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {ERC20} from "solmate/src/tokens/ERC20.sol";

import {Manager} from "../../src/Manager.sol";
import {IOracle} from "../../interfaces/IOracle.sol";

interface IAggregationRouterV6 {
    struct SwapDescription {
        address srcToken;
        address dstToken;
        address payable receiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    function swap(
        IAggregationExecutor caller,
        SwapDescription calldata desc,
        bytes calldata data
    )
        external
        payable
        returns (uint256 returnAmount, uint256 gasLeft);
}

interface IAggregationExecutor {}

contract Swap {
    function swap(
        address srcToken,
        address dstToken,
        uint256 amount,
        uint256 minReturnAmount,
        address executor,
        bytes calldata data
    ) external payable {
        // 1inch Aggregation Router address (currently 0x11111112542D85B3EF69AE05771c2dCCff4fAa26)
        address AGGREGATION_ROUTER = 0x11111112542D85B3EF69AE05771c2dCCff4fAa26;

        // Approve the 1inch router to spend the source token
        // Only needed if srcToken is an actual ERC20 (i.e., not ETH)
        ERC20(srcToken).approve(AGGREGATION_ROUTER, amount);

        // Prepare the swap description
        IAggregationRouterV6.SwapDescription memory desc = IAggregationRouterV6.SwapDescription({
            srcToken: srcToken,
            dstToken: dstToken,
            receiver: payable(msg.sender), // who should get the swapped tokens
            amount: amount,
            minReturnAmount: minReturnAmount,
            flags: 0,         // set any flags if needed (often 0)
            permit: ""        // pass in any permit data if needed, otherwise ""
        });

        // Call the 1inch router to perform the swap
        (uint256 returnAmount, ) = IAggregationRouterV6(AGGREGATION_ROUTER).swap(
            IAggregationExecutor(executor),
            desc,
            data
        );

        // Optional: require that we received at least the minimum
        require(returnAmount >= minReturnAmount, "Insufficient output amount");
    }
}
