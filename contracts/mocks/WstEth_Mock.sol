// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import {ERC20_Mock} from "./ERC20_Mock.sol";

contract WstETH_Mock is ERC20_Mock("Wrapped stETH", "wstETH", 18) {
    uint public stEthPerToken;

    function setStEthPerToken() external view returns (uint256) {
        return stEthPerToken;
    }
}