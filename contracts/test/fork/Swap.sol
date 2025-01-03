// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {ERC20} from "solmate/src/tokens/ERC20.sol";

import {Manager} from "../../src/Manager.sol";
import {IOracle} from "../../interfaces/IOracle.sol";

contract Swap {
    function _swap(bytes memory data, uint amount) public {
        address EXCHANGE_PROXY = 0x0000000000001fF3684f28c67538d4D072C22734;
        ERC20(0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85).transferFrom(msg.sender, address(this), amount);
        ERC20(0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85).approve(0x0000000000001fF3684f28c67538d4D072C22734, amount);

        (bool success, ) = EXCHANGE_PROXY.call{value: 0}(data);
        require(success, "0x swap failed");
    }
}
