// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import {IOracle} from "../interfaces/IOracle.sol";

contract Oracle_Mock is IOracle {
    int256 private _price;

    constructor(int256 initialPrice) {
        _price = initialPrice;
    }

    function decimals() external pure override returns (uint8) {
        return 8;
    }

    function description() external pure override returns (string memory) {
        return "WSTETH / USD";
    }

    function version() external pure override returns (uint256) {
        return 4;
    }

    function getRoundData(uint80 _roundId)
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        require(_roundId == 1, "Only mock round ID 1 is supported");
        return (1, _price, block.timestamp, block.timestamp, 1);
    }

    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (1, _price, block.timestamp, block.timestamp, 1);
    }

    function setPrice(int256 price) external {
        _price = price;
    }
}