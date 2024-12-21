// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

interface IWstETH {
    function stEthPerToken() external view returns (uint256);
}