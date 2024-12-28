// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

library Errors {
    string internal constant ZERO_SHARES             = "Zero Shares";
    string internal constant ZERO_ASSETS             = "Zero Assets";
    string internal constant NOT_DELEGATE            = "Not a Delegate";
    string internal constant NOT_OWNER_OR_DELEGATE   = "Not an Owner or a Delegate";
    string internal constant INSUFFICIENT_COLLATERAL = "Insufficient Collateral";
    string internal constant NOT_UNDERCOLLATERIZED   = "Not Undercollaterized";
    string internal constant NO_DEBT_TO_REPAY        = "Not Undercollaterized";
    string internal constant STALE_DATA              = "Data is Stale";
    string internal constant DEADLINE_EXPIRED        = "The deadline has expired";
    string internal constant INVALID_SIGNATRURE      = "The signature is invalid";
}