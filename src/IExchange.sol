// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IExchange {
    function ethToTokenTransfer(uint256 minAmountToReceive, address recipient)
        external
        payable;
}
