// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {Manager} from "./Manager.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";

struct LockParams {
    address owner;
    address spender;
    uint256 deadline;
    uint8   v;
    bytes32 r;
    bytes32 s;
}

contract Router {
    Manager public manager;
    IOracle public oracle;
    ERC20   public asset;

    modifier unlock(LockParams memory params) { 
        manager.unlock(
            params.owner,
            address(this),
            params.deadline,
            params.v,
            params.r,
            params.s
        );

        _;

        manager.lock(params.owner);
    }

    constructor(Manager _manager) {
        manager = _manager;
        oracle  = manager.oracle();
        asset   = manager.asset();
    }

    function redeem(
        address receiver,
        uint    amount,
        LockParams memory params
    ) external unlock(params){
        manager.burnFUSD(amount, params.owner);
        uint redeemAmount = amount 
                            * (10 ** (oracle.decimals() + asset.decimals())) 
                            / manager.assetPrice() 
                            / 1e18;
        manager.withdraw(redeemAmount, receiver, params.owner);
    }
}