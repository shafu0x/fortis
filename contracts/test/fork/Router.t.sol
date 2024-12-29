// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {ERC20} from "solmate/src/tokens/ERC20.sol";

import {Swap} from "./Swap.sol";

contract Router_Test is Test {
    function test_swap() public {
        Swap swap = new Swap();
        console.log(block.number);
        address shafu = 0x414b60745072088d013721b4a28a0559b1A9d213;
        ERC20 stETH = ERC20(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
        uint balanceShafu = stETH.balanceOf(shafu);
        vm.startPrank(shafu);
        stETH.transfer(address(this), balanceShafu);
        vm.stopPrank();
        stETH.approve(address(swap), balanceShafu);
        swap.swap(
            address(stETH), // stETH
            0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, // USDC
            balanceShafu,
            10,
            ""
        );
    }
}