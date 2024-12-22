// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

import "forge-std/src/Test.sol";

import {ERC20} from "solmate/src/tokens/ERC20.sol";

import {Manager} from "./Manager.sol";
import {IOracle} from "../interfaces/IOracle.sol";

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

    function depositAndMint(
        address receiver,
        uint    assets,
        uint    amount,
        LockParams memory params
    ) external unlock(params) {
        asset.transferFrom(params.owner, address(this), assets);
        manager.deposit(assets, receiver);
        manager.mintFUSD(amount, params.owner, receiver);
    }

    function burnAndWithdraw(
        address receiver,
        uint    assets,
        LockParams memory params
    ) external unlock(params){
        manager.burnFUSD(assets, params.owner);
        uint redeemAssets = assets 
                            * (10 ** (oracle.decimals() + asset.decimals())) 
                            / manager.assetPrice() 
                            / 1e18;
        manager.withdrawFrom(redeemAssets, receiver, params.owner);
    }
}