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
        ERC20 usdc = ERC20(0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85);
        uint balanceShafu = usdc.balanceOf(shafu);
        console.log(balanceShafu);
        vm.startPrank(shafu);
        usdc.transfer(address(this), balanceShafu);
        vm.stopPrank();
        usdc.approve(address(swap), balanceShafu);
        swap.swap(
            address(usdc), 
            0x1F32b1c2345538c0c6f582fCB022739c4A194Ebb, // stETH
            100,
            100,
            address(0),
            ""
        );
    }
}