// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {ERC20} from "solmate/src/tokens/ERC20.sol";

import {Manager} from "../../src/Manager.sol";
import {IOracle} from "../../interfaces/IOracle.sol";

interface I1InchAggregator {
    function swap(
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 minReturn,
        address payable referrer,
        bytes calldata data
    ) external payable returns (uint256 returnAmount);
}

contract Swap {
    function swap(
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 minReturn,
        bytes calldata swapData
    ) public {
        console.log(address(this));
        address AGGREGATOR = 0x1111111254EEB25477B68fb85Ed929f73A960582;
        ERC20(fromToken).transferFrom(msg.sender, address(this), amount);
        ERC20(fromToken).approve(AGGREGATOR, amount);
        I1InchAggregator(AGGREGATOR).swap(
            fromToken,
            toToken,
            amount,
            minReturn,
            payable(msg.sender),
            swapData
        );
    }
}
